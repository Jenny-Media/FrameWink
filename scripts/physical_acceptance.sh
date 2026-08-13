#!/bin/sh

set -eu

FRAMEWINK_REPOSITORY_ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
FRAMEWINK_XCODE_DEVELOPER_DIR=${FRAMEWINK_XCODE_DEVELOPER_DIR:-/Applications/Xcode-beta.app/Contents/Developer}
FRAMEWINK_DERIVED_DATA=${FRAMEWINK_DERIVED_DATA:-/private/tmp/FrameWink-Physical-Acceptance}
FRAMEWINK_BUNDLE_ID=media.jenny.FrameWink

usage() {
    cat <<'EOF'
Usage: scripts/physical_acceptance.sh <prepare|verify-albums|sample|soak> [options]

Commands:
  prepare              Build, install, and launch the real-PhotoKit Debug harness.
  verify-albums        UI-test authorized album discovery on the physical iPad.
  sample               Record one process/lock/heartbeat/screenshot sample.
  soak [hours] [secs]  Monitor the already-running app (defaults: 168 hours, 300 sec).

Environment:
  FRAMEWINK_DEVICE_ID     Physical CoreDevice ID. Auto-detected when exactly one
                          connected physical iPad is available.
  FRAMEWINK_XCODE_UDID    Xcode destination UDID. Auto-detected from CoreDevice.
  FRAMEWINK_ARTIFACTS     Evidence directory (default: TestArtifacts/PhysicalAcceptance).
EOF
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Missing required command: $1" >&2
        exit 1
    }
}

device_json() {
    DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcrun devicectl list devices \
        --json-output "$FRAMEWINK_DEVICE_LIST_JSON" >/dev/null
}

discover_device() {
    require_command jq
    mkdir -p "$FRAMEWINK_ARTIFACTS"
    FRAMEWINK_DEVICE_LIST_JSON="$FRAMEWINK_ARTIFACTS/.devices.json"
    device_json

    if [ -z "${FRAMEWINK_DEVICE_ID:-}" ]; then
        FRAMEWINK_DEVICE_IDS=$(jq -r '
            .result.devices[]
            | select(
                .properties.hardware.reality == "physical"
                and .properties.hardware.deviceType == "iPad"
                and .properties.connection.state == "connected"
            )
            | .identifier
        ' "$FRAMEWINK_DEVICE_LIST_JSON")
        FRAMEWINK_DEVICE_COUNT=$(printf '%s\n' "$FRAMEWINK_DEVICE_IDS" | sed '/^$/d' | wc -l | tr -d ' ')
        [ "$FRAMEWINK_DEVICE_COUNT" = "1" ] || {
            echo "Expected exactly one connected physical iPad; found $FRAMEWINK_DEVICE_COUNT." >&2
            echo "Set FRAMEWINK_DEVICE_ID explicitly when more than one is connected." >&2
            exit 1
        }
        FRAMEWINK_DEVICE_ID=$FRAMEWINK_DEVICE_IDS
    fi

    FRAMEWINK_MATCH_COUNT=$(jq -r --arg id "$FRAMEWINK_DEVICE_ID" '
        [.result.devices[]
         | select(
             .identifier == $id
             and .properties.hardware.reality == "physical"
             and .properties.hardware.deviceType == "iPad"
             and .properties.connection.state == "connected"
         )] | length
    ' "$FRAMEWINK_DEVICE_LIST_JSON")
    [ "$FRAMEWINK_MATCH_COUNT" = "1" ] || {
        echo "FRAMEWINK_DEVICE_ID is not a connected physical iPad." >&2
        exit 1
    }

    if [ -z "${FRAMEWINK_XCODE_UDID:-}" ]; then
        FRAMEWINK_XCODE_UDID=$(jq -r --arg id "$FRAMEWINK_DEVICE_ID" '
            .result.devices[]
            | select(.identifier == $id)
            | .properties.hardware.udid
        ' "$FRAMEWINK_DEVICE_LIST_JSON")
    fi

    FRAMEWINK_DEVICE_MODEL=$(jq -r --arg id "$FRAMEWINK_DEVICE_ID" '
        .result.devices[]
        | select(.identifier == $id)
        | .properties.hardware.marketingName
    ' "$FRAMEWINK_DEVICE_LIST_JSON")
    FRAMEWINK_DEVICE_OS=$(jq -r --arg id "$FRAMEWINK_DEVICE_ID" '
        .result.devices[]
        | select(.identifier == $id)
        | .properties.software.osVersionNumber.stringValue
    ' "$FRAMEWINK_DEVICE_LIST_JSON")
}

write_run_metadata() {
    jq -n \
        --arg startedAt "$FRAMEWINK_STARTED_AT" \
        --arg model "$FRAMEWINK_DEVICE_MODEL" \
        --arg os "$FRAMEWINK_DEVICE_OS" \
        --arg bundleID "$FRAMEWINK_BUNDLE_ID" \
        '{startedAt: $startedAt, deviceModel: $model, osVersion: $os, bundleIdentifier: $bundleID}' \
        > "$FRAMEWINK_ARTIFACTS/run.json"
}

prepare() {
    echo "Building for $FRAMEWINK_DEVICE_MODEL (iPadOS $FRAMEWINK_DEVICE_OS)…"
    DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcodebuild -quiet \
        -project "$FRAMEWINK_REPOSITORY_ROOT/FrameWink.xcodeproj" \
        -scheme FrameWink \
        -configuration Debug \
        -destination "platform=iOS,id=$FRAMEWINK_XCODE_UDID" \
        -derivedDataPath "$FRAMEWINK_DERIVED_DATA" \
        -allowProvisioningUpdates \
        build

    FRAMEWINK_APP_PATH="$FRAMEWINK_DERIVED_DATA/Build/Products/Debug-iphoneos/FrameWink.app"
    DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcrun devicectl device install app \
        --device "$FRAMEWINK_DEVICE_ID" "$FRAMEWINK_APP_PATH"
    write_run_metadata
    if ! DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcrun devicectl device process launch \
        --device "$FRAMEWINK_DEVICE_ID" \
        --terminate-existing \
        --environment-variables '{"FRAMEWINK_PHYSICAL_ACCEPTANCE":"1"}' \
        "$FRAMEWINK_BUNDLE_ID"; then
        echo "FrameWink installed, but iPadOS refused to launch it." >&2
        echo "Unlock the iPad, leave it awake, and rerun prepare." >&2
        exit 1
    fi

    FRAMEWINK_LAUNCH_PROCESS_JSON="$FRAMEWINK_ARTIFACTS/.launch-processes.json"
    FRAMEWINK_LAUNCH_ATTEMPT=0
    FRAMEWINK_LAUNCH_CONFIRMED=false
    while [ "$FRAMEWINK_LAUNCH_ATTEMPT" -lt 10 ]; do
        sleep 1
        if DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcrun devicectl device info processes \
            --device "$FRAMEWINK_DEVICE_ID" \
            --search FrameWink \
            --json-output "$FRAMEWINK_LAUNCH_PROCESS_JSON" >/dev/null 2>&1; then
            if [ "$(jq '.result.runningProcesses | length' "$FRAMEWINK_LAUNCH_PROCESS_JSON")" -gt 0 ]; then
                FRAMEWINK_LAUNCH_CONFIRMED=true
                break
            fi
        fi
        FRAMEWINK_LAUNCH_ATTEMPT=$((FRAMEWINK_LAUNCH_ATTEMPT + 1))
    done
    if [ "$FRAMEWINK_LAUNCH_CONFIRMED" != true ]; then
        echo "The launch request returned, but FrameWink did not stay running." >&2
        echo "Confirm the iPad display is unlocked and rerun prepare." >&2
        exit 1
    fi

    echo
    echo "FrameWink is open in the Debug physical-acceptance harness."
    echo "It grants FrameWink Lifetime locally but uses the real Photos library."
    echo "Follow docs/PHYSICAL_ACCEPTANCE.md, then run:"
    echo "  scripts/physical_acceptance.sh sample"
}

verify_albums() {
    echo "Verifying authorized PhotoKit album discovery on ${FRAMEWINK_DEVICE_MODEL}…"
    set +e
    DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcodebuild -quiet \
        -project "$FRAMEWINK_REPOSITORY_ROOT/FrameWink.xcodeproj" \
        -scheme FrameWink \
        -configuration Debug \
        -destination "platform=iOS,id=$FRAMEWINK_XCODE_UDID" \
        -derivedDataPath "$FRAMEWINK_DERIVED_DATA" \
        -allowProvisioningUpdates \
        -only-testing:FrameWinkUITests/FirstLaunchPrivacyUITests/testAuthorizedPhysicalPhotoLibraryLoadsAlbumPicker \
        test
    FRAMEWINK_VERIFY_ALBUMS_STATUS=$?
    set -e

    echo "Returning the iPad to the interactive FrameWink harness…"
    DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcrun devicectl device process launch \
        --device "$FRAMEWINK_DEVICE_ID" \
        --terminate-existing \
        --environment-variables '{"FRAMEWINK_PHYSICAL_ACCEPTANCE":"1"}' \
        "$FRAMEWINK_BUNDLE_ID"

    if [ "$FRAMEWINK_VERIFY_ALBUMS_STATUS" -ne 0 ]; then
        echo "Authorized physical PhotoKit album discovery failed." >&2
        return "$FRAMEWINK_VERIFY_ALBUMS_STATUS"
    fi
    echo "Authorized physical PhotoKit album discovery passed."
}

copy_heartbeat() {
    if DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcrun devicectl device copy from \
        --device "$FRAMEWINK_DEVICE_ID" \
        --domain-type appDataContainer \
        --domain-identifier "$FRAMEWINK_BUNDLE_ID" \
        --source Library/Application\ Support/FrameWink/PhysicalAcceptance/heartbeat.json \
        --destination "$FRAMEWINK_SAMPLE_DIRECTORY/heartbeat.json" >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

sample() {
    FRAMEWINK_SAMPLE_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    FRAMEWINK_SAMPLE_STAMP=$(date -u +%Y%m%dT%H%M%SZ)
    FRAMEWINK_SAMPLE_DIRECTORY="$FRAMEWINK_ARTIFACTS/samples/$FRAMEWINK_SAMPLE_STAMP"
    mkdir -p "$FRAMEWINK_SAMPLE_DIRECTORY"

    FRAMEWINK_PROCESS_JSON="$FRAMEWINK_SAMPLE_DIRECTORY/processes.json"
    FRAMEWINK_LOCK_JSON="$FRAMEWINK_SAMPLE_DIRECTORY/lock-state.json"
    FRAMEWINK_APP_JSON="$FRAMEWINK_SAMPLE_DIRECTORY/app.json"

    FRAMEWINK_PROCESS_OK=false
    if DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcrun devicectl device info processes \
        --device "$FRAMEWINK_DEVICE_ID" \
        --search FrameWink \
        --json-output "$FRAMEWINK_PROCESS_JSON" >/dev/null 2>&1; then
        if [ "$(jq '.result.runningProcesses | length' "$FRAMEWINK_PROCESS_JSON")" -gt 0 ]; then
            FRAMEWINK_PROCESS_OK=true
        fi
    fi

    FRAMEWINK_CONNECTED=true
    if ! DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcrun devicectl device info lockState \
        --device "$FRAMEWINK_DEVICE_ID" \
        --json-output "$FRAMEWINK_LOCK_JSON" >/dev/null 2>&1; then
        FRAMEWINK_CONNECTED=false
    fi

    DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcrun devicectl device info apps \
        --device "$FRAMEWINK_DEVICE_ID" \
        --bundle-id "$FRAMEWINK_BUNDLE_ID" \
        --json-output "$FRAMEWINK_APP_JSON" >/dev/null 2>&1 || true

    DEVELOPER_DIR="$FRAMEWINK_XCODE_DEVELOPER_DIR" xcrun devicectl device capture screenshot \
        --device "$FRAMEWINK_DEVICE_ID" \
        --destination "$FRAMEWINK_SAMPLE_DIRECTORY/screen.png" >/dev/null 2>&1 || true

    copy_heartbeat

    FRAMEWINK_HEARTBEAT_PRESENT=false
    FRAMEWINK_THERMAL_STATE=unknown
    FRAMEWINK_BATTERY_STATE=unknown
    FRAMEWINK_BATTERY_LEVEL=null
    FRAMEWINK_IDLE_TIMER=null
    FRAMEWINK_GUIDED_ACCESS=null
    if [ -f "$FRAMEWINK_SAMPLE_DIRECTORY/heartbeat.json" ]; then
        FRAMEWINK_HEARTBEAT_PRESENT=true
        FRAMEWINK_THERMAL_STATE=$(jq -r '.thermalState // "unknown"' "$FRAMEWINK_SAMPLE_DIRECTORY/heartbeat.json")
        FRAMEWINK_BATTERY_STATE=$(jq -r '.batteryState // "unknown"' "$FRAMEWINK_SAMPLE_DIRECTORY/heartbeat.json")
        FRAMEWINK_BATTERY_LEVEL=$(jq -r 'if .batteryLevel == null then "null" else .batteryLevel end' "$FRAMEWINK_SAMPLE_DIRECTORY/heartbeat.json")
        FRAMEWINK_IDLE_TIMER=$(jq -r 'if .idleTimerDisabled == null then "null" else .idleTimerDisabled end' "$FRAMEWINK_SAMPLE_DIRECTORY/heartbeat.json")
        FRAMEWINK_GUIDED_ACCESS=$(jq -r 'if .guidedAccessEnabled == null then "null" else .guidedAccessEnabled end' "$FRAMEWINK_SAMPLE_DIRECTORY/heartbeat.json")
    fi

    jq -n \
        --arg timestamp "$FRAMEWINK_SAMPLE_AT" \
        --argjson connected "$FRAMEWINK_CONNECTED" \
        --argjson processRunning "$FRAMEWINK_PROCESS_OK" \
        --argjson heartbeatPresent "$FRAMEWINK_HEARTBEAT_PRESENT" \
        --arg thermalState "$FRAMEWINK_THERMAL_STATE" \
        --arg batteryState "$FRAMEWINK_BATTERY_STATE" \
        --argjson batteryLevel "$FRAMEWINK_BATTERY_LEVEL" \
        --argjson idleTimerDisabled "$FRAMEWINK_IDLE_TIMER" \
        --argjson guidedAccessEnabled "$FRAMEWINK_GUIDED_ACCESS" \
        '{timestamp: $timestamp, connected: $connected, processRunning: $processRunning,
          heartbeatPresent: $heartbeatPresent, thermalState: $thermalState,
          batteryState: $batteryState, batteryLevel: $batteryLevel,
          idleTimerDisabled: $idleTimerDisabled, guidedAccessEnabled: $guidedAccessEnabled}' \
        > "$FRAMEWINK_SAMPLE_DIRECTORY/summary.json"
    jq -c . "$FRAMEWINK_SAMPLE_DIRECTORY/summary.json" >> "$FRAMEWINK_ARTIFACTS/timeline.jsonl"

    if [ "$FRAMEWINK_CONNECTED" != true ] || [ "$FRAMEWINK_PROCESS_OK" != true ]; then
        printf '%s connected=%s processRunning=%s\n' \
            "$FRAMEWINK_SAMPLE_AT" "$FRAMEWINK_CONNECTED" "$FRAMEWINK_PROCESS_OK" \
            >> "$FRAMEWINK_ARTIFACTS/incidents.log"
    fi

    echo "$FRAMEWINK_SAMPLE_AT connected=$FRAMEWINK_CONNECTED process=$FRAMEWINK_PROCESS_OK thermal=$FRAMEWINK_THERMAL_STATE battery=$FRAMEWINK_BATTERY_STATE"
}

soak() {
    FRAMEWINK_HOURS=${1:-168}
    FRAMEWINK_INTERVAL_SECONDS=${2:-300}
    case "$FRAMEWINK_HOURS:$FRAMEWINK_INTERVAL_SECONDS" in
        *[!0-9.:]*)
            echo "Hours and interval must be positive numbers." >&2
            exit 1
            ;;
    esac
    FRAMEWINK_END_EPOCH=$(awk -v now="$(date +%s)" -v hours="$FRAMEWINK_HOURS" \
        'BEGIN { printf "%.0f", now + (hours * 3600) }')
    echo "Monitoring for $FRAMEWINK_HOURS hour(s), every $FRAMEWINK_INTERVAL_SECONDS second(s)."
    while [ "$(date +%s)" -lt "$FRAMEWINK_END_EPOCH" ]; do
        sample || true
        FRAMEWINK_REMAINING=$((FRAMEWINK_END_EPOCH - $(date +%s)))
        [ "$FRAMEWINK_REMAINING" -le 0 ] && break
        if [ "$FRAMEWINK_REMAINING" -lt "$FRAMEWINK_INTERVAL_SECONDS" ]; then
            sleep "$FRAMEWINK_REMAINING"
        else
            sleep "$FRAMEWINK_INTERVAL_SECONDS"
        fi
    done
    sample || true
    echo "Soak monitoring finished. Evidence: $FRAMEWINK_ARTIFACTS"
}

[ $# -ge 1 ] || {
    usage
    exit 1
}

FRAMEWINK_COMMAND=$1
shift

case "$FRAMEWINK_COMMAND" in
    -h|--help|help)
        usage
        exit 0
        ;;
esac

FRAMEWINK_ARTIFACTS=${FRAMEWINK_ARTIFACTS:-$FRAMEWINK_REPOSITORY_ROOT/TestArtifacts/PhysicalAcceptance}
FRAMEWINK_STARTED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
discover_device

case "$FRAMEWINK_COMMAND" in
    prepare)
        prepare
        ;;
    verify-albums)
        verify_albums
        ;;
    sample)
        sample
        ;;
    soak)
        soak "$@"
        ;;
    *)
        echo "Unknown command: $FRAMEWINK_COMMAND" >&2
        usage >&2
        exit 1
        ;;
esac
