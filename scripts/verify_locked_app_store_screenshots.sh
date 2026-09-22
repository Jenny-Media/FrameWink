#!/bin/bash

set -euo pipefail

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

for device_family in iPad-13-inch iPhone-6.9-inch; do
    lock_root="$repo_root/AppStore/Screenshots/ProductPageOptimization/$device_family"
    cd "$lock_root/Final"
    shasum -a 256 -c ../LOCKED_SHA256SUMS
done

echo "The locked iPad and iPhone App Store screenshot sets are unchanged."
