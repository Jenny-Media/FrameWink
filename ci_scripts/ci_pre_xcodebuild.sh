#!/bin/sh

set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_path=${CI_PRIMARY_REPOSITORY_PATH:-$(CDPATH= cd -- "$script_directory/.." && pwd)}
project_path="$repository_path/FrameWink.xcodeproj"
scheme_name="FrameWink"

fail() {
    echo "FrameWink release guard: $1" >&2
    exit 1
}

read_build_setting() {
    setting_name=$1
    printf '%s\n' "$build_settings" \
        | awk -F ' = ' -v name="$setting_name" '$1 ~ "^[[:space:]]*" name "$" { print $2; exit }'
}

[ -d "$project_path" ] || fail "FrameWink.xcodeproj is missing."
[ -f "$repository_path/FrameWink/Info.plist" ] || fail "Info.plist is missing."
[ -f "$repository_path/FrameWink/PrivacyInfo.xcprivacy" ] \
    || fail "PrivacyInfo.xcprivacy is missing."

plutil -lint "$repository_path/FrameWink/Info.plist"
plutil -lint "$repository_path/FrameWink/PrivacyInfo.xcprivacy"

build_settings=$(xcodebuild \
    -project "$project_path" \
    -scheme "$scheme_name" \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -showBuildSettings)

bundle_identifier=$(read_build_setting PRODUCT_BUNDLE_IDENTIFIER)
development_team=$(read_build_setting DEVELOPMENT_TEAM)
device_family=$(read_build_setting TARGETED_DEVICE_FAMILY)
minimum_os=$(read_build_setting IPHONEOS_DEPLOYMENT_TARGET)
wall_mode_product_id=$(read_build_setting FRAMEWINK_WALL_MODE_PRODUCT_ID)
unit_test_bundle_identifier=$(xcodebuild \
    -project "$project_path" \
    -target FrameWinkTests \
    -configuration Release \
    -sdk iphoneos \
    -showBuildSettings \
    | awk -F ' = ' '$1 ~ "^[[:space:]]*PRODUCT_BUNDLE_IDENTIFIER$" { print $2; exit }')
ui_test_bundle_identifier=$(xcodebuild \
    -project "$project_path" \
    -target FrameWinkUITests \
    -configuration Release \
    -sdk iphoneos \
    -showBuildSettings \
    | awk -F ' = ' '$1 ~ "^[[:space:]]*PRODUCT_BUNDLE_IDENTIFIER$" { print $2; exit }')

[ "$bundle_identifier" = "media.jenny.FrameWink" ] \
    || fail "Release bundle identifier is '$bundle_identifier', expected media.jenny.FrameWink."
[ "$development_team" = "5736QK4NZX" ] \
    || fail "Release development team is '$development_team', expected Jenny Media LLC (5736QK4NZX)."
[ "$device_family" = "1,2" ] \
    || fail "Release target must support iPhone and iPad (TARGETED_DEVICE_FAMILY = 1,2)."
[ "$minimum_os" = "15.0" ] \
    || fail "Release deployment target is '$minimum_os', expected iOS/iPadOS 15.0."
[ "$unit_test_bundle_identifier" = "media.jenny.FrameWinkTests" ] \
    || fail "Unit-test bundle identifier is '$unit_test_bundle_identifier', expected media.jenny.FrameWinkTests."
[ "$ui_test_bundle_identifier" = "media.jenny.FrameWinkUITests" ] \
    || fail "UI-test bundle identifier is '$ui_test_bundle_identifier', expected media.jenny.FrameWinkUITests."

if [ "${CI_XCODEBUILD_ACTION:-}" = "archive" ]; then
    [ "${CI_BUNDLE_ID:-$bundle_identifier}" = "media.jenny.FrameWink" ] \
        || fail "Xcode Cloud archive product has the wrong bundle identifier."
    [ "${CI_TEAM_ID:-$development_team}" = "5736QK4NZX" ] \
        || fail "Xcode Cloud archive is not using the Jenny Media LLC team."
    [ -n "$wall_mode_product_id" ] \
        || fail "Release Wall Mode product identifier is empty; confirm the immutable App Store Connect product before archiving."
    [ "$wall_mode_product_id" = "media.jenny.FrameWink.wallmode" ] \
        || fail "The TestFlight archive must use the production FrameWink Lifetime product identifier."
fi

echo "FrameWink release guard passed for ${CI_XCODEBUILD_ACTION:-local validation}."
