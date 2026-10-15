#!/usr/bin/env bash
# Build FilterData.appex and FilterControl.appex without a signing identity,
# then stage them where the MAUI AdditionalAppExtensions items expect them.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED="${ROOT}/artifacts/xcode-derived"
PRODUCTS="${DERIVED}/Build/Products/Release-iphoneos"
STAGE="${ROOT}/artifacts/appex"

echo "Building Network Extension targets (unsigned)"
xcodebuild \
  -project "${ROOT}/extensions/FilterExtensions/FilterExtensions.xcodeproj" \
  -scheme FilterExtensions \
  -configuration Release \
  -destination "generic/platform=iOS" \
  -derivedDataPath "${DERIVED}" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=- \
  build

stage_appex() {
  local name="$1"
  local source="${PRODUCTS}/${name}.appex"
  local destination="${STAGE}/${name}/Release-iphoneos"
  if [[ ! -d "${source}" ]]; then
    echo "error: ${source} was not produced" >&2
    exit 1
  fi
  rm -rf "${destination}"
  mkdir -p "${destination}"
  cp -R "${source}" "${destination}/"
  echo "Staged ${destination}/${name}.appex"
}

stage_appex FilterData
stage_appex FilterControl

expect_extension_point() {
  local name="$1"
  local expected="$2"
  local plist="${STAGE}/${name}/Release-iphoneos/${name}.appex/Info.plist"
  local actual
  actual="$(plutil -extract NSExtension.NSExtensionPointIdentifier raw -o - "${plist}")"
  if [[ "${actual}" != "${expected}" ]]; then
    echo "error: ${name} extension point is '${actual}', expected '${expected}'" >&2
    exit 1
  fi
  echo "${name} extension point is ${actual}"
}

expect_extension_point FilterData "com.apple.networkextension.filter-data"
expect_extension_point FilterControl "com.apple.networkextension.filter-control"
