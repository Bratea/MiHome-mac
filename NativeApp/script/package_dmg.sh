#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUTPUT_DIR="$ROOT_DIR/../dist"
DMG_PATH="$OUTPUT_DIR/MiHome-1.0.0-macOS-native.dmg"

"$ROOT_DIR/script/build_and_run.sh" bundle
mkdir -p "$OUTPUT_DIR"
# build_and_run.sh also refreshes "$OUTPUT_DIR/MiHome Test.app" for direct testing.
hdiutil create \
  -volname "米家" \
  -srcfolder "$ROOT_DIR/dist/MiHome.app" \
  -format UDZO \
  -ov \
  "$DMG_PATH"
shasum -a 256 "$DMG_PATH"
