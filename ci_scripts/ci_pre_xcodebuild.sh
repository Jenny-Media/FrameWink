#!/bin/sh

set -eu

script_directory=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repository_path=${CI_PRIMARY_REPOSITORY_PATH:-$(CDPATH= cd -- "$script_directory/.." && pwd)}
project_path="$repository_path/FrameWink.xcodeproj"
scheme_name="FrameWink"
developer_team_id="5736QK4NZX"
app_store_connect_team_id="69a6de81-5b05-47e3-e053-5b8c7c11a4d1"
xcodebuild_action=${CI_XCODEBUILD_ACTION:-}

fail() {
    echo "FrameWink release guard: $1" >&2
    exit 1
}

if [ "$xcodebuild_action" = "test-without-building" ] && [ ! -d "$project_path" ]; then
    echo "FrameWink release guard skipped for artifact-only test worker; build-for-testing already validated the source checkout."
    exit 0
fi

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
supports_mac_compatibility=$(read_build_setting SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD)
supports_xr_compatibility=$(read_build_setting SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD)
minimum_os=$(read_build_setting IPHONEOS_DEPLOYMENT_TARGET)
marketing_version=$(read_build_setting MARKETING_VERSION)
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
[ "$development_team" = "$developer_team_id" ] \
    || fail "Release development team is '$development_team', expected Jenny Media LLC (5736QK4NZX)."
[ "$device_family" = "1,2" ] \
    || fail "Release target must support iPhone and iPad (TARGETED_DEVICE_FAMILY = 1,2)."
[ "$supports_mac_compatibility" = "NO" ] \
    || fail "Release target must not be available as Designed for iPhone/iPad on Mac."
[ "$supports_xr_compatibility" = "NO" ] \
    || fail "Release target must not be available as Designed for iPhone/iPad on Apple Vision Pro."
[ "$minimum_os" = "15.0" ] \
    || fail "Release deployment target is '$minimum_os', expected iOS/iPadOS 15.0."
[ "$marketing_version" = "1.0" ] \
    || fail "Release marketing version is '$marketing_version', expected App Store version 1.0."
[ "$unit_test_bundle_identifier" = "media.jenny.FrameWinkTests" ] \
    || fail "Unit-test bundle identifier is '$unit_test_bundle_identifier', expected media.jenny.FrameWinkTests."
[ "$ui_test_bundle_identifier" = "media.jenny.FrameWinkUITests" ] \
    || fail "UI-test bundle identifier is '$ui_test_bundle_identifier', expected media.jenny.FrameWinkUITests."

if [ "$xcodebuild_action" = "archive" ]; then
    [ "${CI_BUNDLE_ID:-$bundle_identifier}" = "media.jenny.FrameWink" ] \
        || fail "Xcode Cloud archive product has the wrong bundle identifier."
    cloud_team_id=${CI_TEAM_ID:-$development_team}
    case "$cloud_team_id" in
        "$developer_team_id"|"$app_store_connect_team_id") ;;
        *) fail "Xcode Cloud archive is not using the Jenny Media LLC team." ;;
    esac
    [ -n "$wall_mode_product_id" ] \
        || fail "Release Wall Mode product identifier is empty; confirm the immutable App Store Connect product before archiving."
    [ "$wall_mode_product_id" = "media.jenny.FrameWink.wallmode" ] \
        || fail "The TestFlight archive must use the production FrameWink Lifetime product identifier."
fi

echo "FrameWink release guard passed for ${xcodebuild_action:-local validation}."
