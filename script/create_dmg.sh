#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="MiHome"
VERSION="$(sed -n 's/__version__ = "\(.*\)"/\1/p' "$ROOT_DIR/app/__init__.py" | head -n 1)"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
DMG_PATH="$ROOT_DIR/dist/$APP_NAME-$VERSION-macOS.dmg"
STAGE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/mihome-dmg.XXXXXX")"

cleanup() {
  rm -rf "$STAGE_DIR"
}
trap cleanup EXIT

if [[ ! -d "$APP_BUNDLE" ]]; then
  "$ROOT_DIR/script/build_and_run.sh" --verify
fi

cp -R "$APP_BUNDLE" "$STAGE_DIR/$APP_NAME.app"
ln -s /Applications "$STAGE_DIR/Applications"
rm -f "$DMG_PATH"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

hdiutil verify "$DMG_PATH"
echo "Created $DMG_PATH"
