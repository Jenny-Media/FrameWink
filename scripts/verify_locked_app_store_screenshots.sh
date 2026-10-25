#!/bin/bash

set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

for device_family in iPad-13-inch iPhone-6.9-inch iPhone-Duo; do
    lock_root="$repo_root/AppStore/Screenshots/ProductPageOptimization/$device_family"
    cd "$lock_root/Final"
    shasum -a 256 -c ../LOCKED_SHA256SUMS
done

# The earlier four-card Duo proof is retained above; the six-card 1.6 gallery
# is the approved Duo release set also retained for 1.6.1.
cd "$repo_root/AppStore/Version-1.6/Screenshots/iPhone-Duo"
shasum -a 256 -c APPROVED_SHA256SUMS

echo "All 23 locked screenshot files are unchanged (19 release cards and four earlier Duo proofs)."
