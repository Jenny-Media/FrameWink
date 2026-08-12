import Foundation

protocol PhotoCurating {
    func makeReel(
        from photos: [AnalyzedPhoto],
        exclusions: Set<UUID>,
        displayHistory: [UUID: DisplayHistoryEntry],
        maximumCount: Int,
        now: Date,
        reelID: UUID
    ) throws -> SmartReel
}

extension PhotoCurating {
    func makeReel(
        from photos: [AnalyzedPhoto],
        exclusions: Set<UUID>,
        maximumCount: Int,
        now: Date,
        reelID: UUID
    ) throws -> SmartReel {
        try makeReel(
            from: photos,
            exclusions: exclusions,
            displayHistory: [:],
            maximumCount: maximumCount,
            now: now,
            reelID: reelID
        )
    }
}

struct SmartReelCurator: PhotoCurating {
    static let algorithmRevision = 2

    private let duplicateDistanceThreshold = 0.12
    private let comparisonWindow = 8
    private let eventSelectionLimit = 3

    func makeReel(
        from photos: [AnalyzedPhoto],
        exclusions: Set<UUID>,
        displayHistory: [UUID: DisplayHistoryEntry],
        maximumCount: Int = 30,
        now: Date = Date(),
        reelID: UUID = UUID()
    ) throws -> SmartReel {
        try Task.checkCancellation()

        let eligible = photos
            .filter { !exclusions.contains($0.candidate.id) }
            .filter { !$0.candidate.isHidden && !$0.candidate.isScreenshot }
            .filter { isDisplayable($0.signals) }

        let burstWinners = suppressBurstAndTimeNeighbors(in: eligible)
        let distinct = try suppressNearDuplicates(in: burstWinners)
        let ranked = rank(distinct, displayHistory: displayHistory, now: now)
        let selected = selectWithDateDiversity(ranked, maximumCount: max(maximumCount, 0))

        return SmartReel(
            id: reelID,
            algorithmRevision: Self.algorithmRevision,
            createdAt: now,
            selections: selected.map(\.curatedPhoto)
        )
    }

    private func isDisplayable(_ signals: PhotoSignals) -> Bool {
        signals.algorithmRevision == Self.algorithmRevision
            && signals.sharpness >= 0.08
            && signals.exposure >= 0.06
            && signals.exposure <= 0.94
            && signals.contrast >= 0.04
    }

    private func suppressBurstAndTimeNeighbors(
        in photos: [AnalyzedPhoto]
    ) -> [AnalyzedPhoto] {
        let ordered = photos.sorted(by: stableChronologicalOrder)
        var groups: [[AnalyzedPhoto]] = []

        for photo in ordered {
            if let last = groups.indices.last,
               belongsToSameCaptureGroup(photo, as: groups[last].last) {
                groups[last].append(photo)
            } else {
                groups.append([photo])
            }
        }

        return groups.compactMap { group in
            group.max(by: lessPreferred)
        }
    }

    private func belongsToSameCaptureGroup(
        _ photo: AnalyzedPhoto,
        as previous: AnalyzedPhoto?
    ) -> Bool {
        guard let previous = previous else { return false }

        if let burst = photo.candidate.burstIdentifier,
           !burst.isEmpty,
           burst == previous.candidate.burstIdentifier {
            return true
        }

        guard photo.candidate.burstIdentifier == nil,
              previous.candidate.burstIdentifier == nil,
              let date = photo.candidate.creationDate,
              let previousDate = previous.candidate.creationDate else {
            return false
        }
        return abs(date.timeIntervalSince(previousDate)) <= 2
    }

    private func suppressNearDuplicates(
        in photos: [AnalyzedPhoto]
    ) throws -> [AnalyzedPhoto] {
        let buckets = Dictionary(grouping: photos, by: comparisonBucket)
        var winners: [AnalyzedPhoto] = []

        for bucketKey in buckets.keys.sorted() {
            try Task.checkCancellation()
            let ordered = (buckets[bucketKey] ?? []).sorted(by: morePreferred)
            var accepted: [AnalyzedPhoto] = []

            for photo in ordered {
                try Task.checkCancellation()
                let nearby = accepted.suffix(comparisonWindow)
                let isDuplicate = nearby.contains { existing in
                    guard let first = photo.featurePrint,
                          let second = existing.featurePrint,
                          let distance = first.normalizedDistance(to: second) else {
                        return false
                    }
                    return distance <= duplicateDistanceThreshold
                }
                if !isDuplicate {
                    accepted.append(photo)
                }
            }
            winners.append(contentsOf: accepted)
        }

        return winners
    }

    private func comparisonBucket(_ photo: AnalyzedPhoto) -> String {
        guard let date = photo.candidate.creationDate else { return "unknown" }
        return Self.dayFormatter.string(from: date)
    }

    private func rank(
        _ photos: [AnalyzedPhoto],
        displayHistory: [UUID: DisplayHistoryEntry],
        now: Date
    ) -> [RankedPhoto] {
        let dated = photos.compactMap(\.candidate.creationDate)
        let oldest = dated.min()
        let newest = dated.max()
        let dateRange = max(newest?.timeIntervalSince(oldest ?? newest ?? Date()) ?? 0, 1)

        return photos.map { photo in
            let recency: Double
            if let date = photo.candidate.creationDate, let oldest = oldest {
                recency = date.timeIntervalSince(oldest) / dateRange
            } else {
                recency = 0.5
            }

            let recencyBalance = 1 - abs(recency - 0.5) * 0.16
            let repeatFitness = repeatFitness(
                for: displayHistory[photo.candidate.id],
                now: now
            )
            let score = min(
                max(photo.signals.qualityScore * recencyBalance * repeatFitness, 0),
                1
            )
            return RankedPhoto(
                photo: photo,
                score: score,
                reasons: reasons(for: photo.signals)
            )
        }
        .sorted(by: rankedBefore)
    }

    private func repeatFitness(
        for history: DisplayHistoryEntry?,
        now: Date
    ) -> Double {
        guard let history = history else { return 1 }
        let countFitness = 1 / (1 + Double(max(history.displayCount, 0)) * 0.12)
        let age = max(now.timeIntervalSince(history.lastDisplayedAt), 0)
        let recentFitness: Double
        if age < 7 * 86_400 {
            recentFitness = 0.65
        } else if age < 30 * 86_400 {
            recentFitness = 0.82
        } else {
            recentFitness = 1
        }
        return max(countFitness * recentFitness, 0.2)
    }

    private func selectWithDateDiversity(
        _ ranked: [RankedPhoto],
        maximumCount: Int
    ) -> [RankedPhoto] {
        guard maximumCount > 0 else { return [] }

        var selection: [RankedPhoto] = []
        var selectedIDs: Set<UUID> = []
        var eventCounts: [String: Int] = [:]
        var deferred: [RankedPhoto] = []

        let dated = ranked.compactMap { item in
            item.photo.candidate.creationDate.map { ($0, item) }
        }.sorted { $0.0 < $1.0 }
        if maximumCount >= 2, dated.count >= 4 {
            let midpoint = dated.count / 2
            let eraRepresentatives = [
                dated[..<midpoint].map { $0.1 }.sorted(by: rankedBefore).first,
                dated[midpoint...].map { $0.1 }.sorted(by: rankedBefore).first,
            ].compactMap { $0 }
            for item in eraRepresentatives {
                let event = comparisonBucket(item.photo)
                selection.append(item.addingDateDiversityReason(if: true))
                selectedIDs.insert(item.photo.candidate.id)
                eventCounts[event, default: 0] += 1
            }
        }

        for item in ranked where !selectedIDs.contains(item.photo.candidate.id) {
            let event = comparisonBucket(item.photo)
            if event == "unknown" || eventCounts[event, default: 0] < eventSelectionLimit {
                selection.append(item.addingDateDiversityReason(if: event != "unknown"))
                selectedIDs.insert(item.photo.candidate.id)
                eventCounts[event, default: 0] += 1
            } else {
                deferred.append(item)
            }
            if selection.count == maximumCount {
                return selection.sorted(by: rankedBefore)
            }
        }

        for item in deferred where selection.count < maximumCount {
            selection.append(item)
        }
        return selection.sorted(by: rankedBefore)
    }

    private func reasons(for signals: PhotoSignals) -> [CurationReason] {
        var reasons: [CurationReason] = [.quality]
        if (signals.faceQuality ?? 0) >= 0.6 { reasons.append(.face) }
        if (signals.saliencyConfidence ?? 0) >= 0.6 { reasons.append(.saliency) }
        if signals.layoutFitness >= 0.7 { reasons.append(.layout) }
        return reasons
    }

    private func stableChronologicalOrder(_ lhs: AnalyzedPhoto, _ rhs: AnalyzedPhoto) -> Bool {
        switch (lhs.candidate.creationDate, rhs.candidate.creationDate) {
        case let (left?, right?):
            if left != right { return left < right }
            return lhs.candidate.id.uuidString < rhs.candidate.id.uuidString
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            return lhs.candidate.id.uuidString < rhs.candidate.id.uuidString
        }
    }

    private func morePreferred(_ lhs: AnalyzedPhoto, _ rhs: AnalyzedPhoto) -> Bool {
        if lhs.signals.qualityScore != rhs.signals.qualityScore {
            return lhs.signals.qualityScore > rhs.signals.qualityScore
        }
        return lhs.candidate.id.uuidString < rhs.candidate.id.uuidString
    }

    private func lessPreferred(_ lhs: AnalyzedPhoto, _ rhs: AnalyzedPhoto) -> Bool {
        morePreferred(rhs, lhs)
    }

    private func rankedBefore(_ lhs: RankedPhoto, _ rhs: RankedPhoto) -> Bool {
        if lhs.score != rhs.score { return lhs.score > rhs.score }
        return lhs.photo.candidate.id.uuidString < rhs.photo.candidate.id.uuidString
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private struct RankedPhoto {
    let photo: AnalyzedPhoto
    let score: Double
    let reasons: [CurationReason]

    var curatedPhoto: CuratedPhoto {
        CuratedPhoto(
            candidateID: photo.candidate.id,
            algorithmRevision: SmartReelCurator.algorithmRevision,
            finalScore: score,
            reasons: reasons,
            importantRects: photo.signals.importantRects
        )
    }

    func addingDateDiversityReason(if condition: Bool) -> RankedPhoto {
        guard condition, !reasons.contains(.dateDiversity) else { return self }
        return RankedPhoto(photo: photo, score: score, reasons: reasons + [.dateDiversity])
    }
}
