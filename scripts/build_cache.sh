#!/bin/sh
# Source this before a build workflow. The launcher holds its lock through export/install.
framewink_cached_workflow() {
    framewink_sdk=$1
    framewink_signing=$2
    shift 2
    framewink_checkout=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
    framewink_profile="$framewink_sdk:Debug:$framewink_signing"
    if [ "${FRAMEWINK_CACHE_CHECKOUT:-}" = "$framewink_checkout" ] && \
       [ "${FRAMEWINK_CACHE_PROFILE:-}" = "$framewink_profile" ]; then
        return
    fi
    if [ "$framewink_signing" = unsigned ]; then
        exec python3 "$framewink_checkout/scripts/build_local.py" --sdk "$framewink_sdk" \
            --unsigned --script "$0" -- "$@"
    fi
    exec python3 "$framewink_checkout/scripts/build_local.py" --sdk "$framewink_sdk" \
        --script "$0" -- "$@"
}
