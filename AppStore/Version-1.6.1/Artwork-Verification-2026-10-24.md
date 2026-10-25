# Artwork verification and gallery — 2026-10-24

The artwork-validator blocker is resolved. The approved release set remains
**six iPhone + seven iPad + six Duo cards**, unchanged from prior approvals.
[View every card in order](Screenshot-Gallery.md). These marketing images were
not recaptured from candidate 1.6.1 (80); native Simulator pose evidence remains
in the separate release verification record.

## What changed

The initial validator stopped at eleven iPad landscape source JPEGs against a
stale expectation of ten. `11-landscape-sample-setup.jpg` was already on main.
The script also retained the filenames of an older ten-card iPad treatment,
although the approved current gallery has seven cards. Corrected both explicit
inventories without deleting or generating an image. The eleven-image source
library is distinct from the seven-card iPad release gallery.

The same validator now checks the six approved iPhone cards and six current Duo
cards. Duo card 4 is the closed-display 1398 × 2034 image; the other five are
2007 × 2853. Exact counts, filenames, dimensions, absence of alpha and per-set
byte uniqueness remain required. The common approval verifier now includes
`Version-1.6/Screenshots/iPhone-Duo/APPROVED_SHA256SUMS`, alongside the prior
17 locked cards/proofs. The main validator invokes this approval check too.
No checksum file, app source, test source, signing setting or archive changed.

## Results

| Check | Result |
| --- | --- |
| Full asset validator | Pass: 86 screenshot JPEGs, IAP review JPEG and app icon |
| Existing approval hashes | 23/23 pass: 19 release cards and four earlier Duo proofs |
| Disposable validator fixtures | Valid fixture passes; seven invalid fixtures rejected |
| Existing tooling unit tests | 30 passed, zero failures |
| Shell syntax, tester-note sync, diff hygiene | Pass |
| Tracked artwork preservation | All 162 image/artwork files have identical SHA-256 values |
| App/project preservation | All 85 inputs match signed archive source `8bfb9bd` |
| App/project/test preservation | All 111 inputs match the final three Simulator suites |
| Local gallery browser verification | 19/19 decode; 6/7/6 order; controls and mobile layout pass |

The invalid fixtures cover extra, missing, misnamed and duplicate images, wrong
pixel dimensions, alpha and a modified sixth current Duo card's approval hash.
Only disposable copies are altered. The original failure remains in
`validator-before.log`; the successful complete run is `validator-after.log`.

The local interactive gallery embeds the exact bytes of all 19 approved JPEGs.
Every embedded hash matches its source; `gallery-manifest.json` records order,
paths and hashes. A headless browser decoded each image, traversed all 19 in
order using arrow keys, checked original-JPEG download links and Escape, and
checked a 390px viewport for horizontal overflow and JavaScript errors. All pass.
The bundled Playwright package's expected browser was absent; the check used
the already installed Chromium 1243 executable with an isolated temporary
profile. No browser download or personal browser-profile access was needed.

## Reproduction and evidence

Run from the isolated release worktree. All evidence below is retained under
ignored `TestArtifacts/ReleasePrep-20261024/ArtworkFix/`.

```sh
sh scripts/validate_app_store_assets.sh
bash scripts/verify_locked_app_store_screenshots.sh
python3 -m unittest discover -s scripts/tests -v
sh -n scripts/validate_app_store_assets.sh
bash -n scripts/*.sh ci_scripts/*.sh
cmp TestFlight/WhatToTest.en-US.txt AppStore/Version-1.6.1/What-to-Test.txt
git diff --check

python3 TestArtifacts/ReleasePrep-20261024/ArtworkFix/framewink-validator-probes.py
python3 TestArtifacts/ReleasePrep-20261024/ArtworkFix/framewink-review-gallery.py
python3 -m http.server 53841 --bind 127.0.0.1 \
  --directory TestArtifacts/ReleasePrep-20261024/ArtworkFix
# With that review-only loopback server running in a separate terminal:
ARTWORK_OUTPUT="$PWD/TestArtifacts/ReleasePrep-20261024/ArtworkFix" \
  /Users/yihong/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node \
  TestArtifacts/ReleasePrep-20261024/ArtworkFix/framewink-gallery-browser-check.cjs
```

Review URL while the local server is running:
`http://127.0.0.1:53841/Screenshot-Gallery.html`. The self-contained HTML also
works offline in a browser; it requires no server or network for its images.
It is a local review artifact and is not part of the product website.

Additional receipts: `validator-probes.json`, `tooling-tests.log`,
`artwork-before.json`, `artwork-source-audit.json`, `gallery-browser-check.json`,
and full-family browser screenshots. The only two differences among the prior
134 gate input fingerprints are the two artwork scripts. App and test sources
are unchanged, so no additional native build or Simulator suite was run for
this tooling/documentation follow-up. Prior full iPhone/iPad/Duo results remain
254 passed / 0 failed / 4 physical-only skips per family, with the previously
recorded runtime/SDK warnings. The signed archive and IPA remain unchanged.

TestFlight hardware acceptance, future live version/build recheck and the
exact-source Xcode Cloud distribution audit remain outstanding. Keep PR #32
draft. No upload, Cloud start, physical-device action, merge, App Review
submission or production publication was performed. Existing GitHub/Vercel
PR previews can update automatically when the release branch is pushed.
