#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="MiHomeNative"
PRODUCT_NAME="MiHome"
MODE="${1:-run}"
APP_DIR="$ROOT_DIR/dist/$PRODUCT_NAME.app"
PROTOCOL_DIR="$ROOT_DIR/.build/protocol/dist/MiHomeProtocol"

cd "$ROOT_DIR"
pkill -x "$PRODUCT_NAME" >/dev/null 2>&1 || true
swift build
"$ROOT_DIR/script/build_protocol_bridge.sh"

BIN_PATH="$(swift build --show-bin-path)/$APP_NAME"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$PRODUCT_NAME"
cp "$ROOT_DIR/../resources/MiHome.icns" "$APP_DIR/Contents/Resources/MiHome.icns"
cp "$ROOT_DIR/AppBundle/Info.plist" "$APP_DIR/Contents/Info.plist"
mkdir -p "$APP_DIR/Contents/Resources/Protocol"
ditto "$PROTOCOL_DIR" "$APP_DIR/Contents/Resources/Protocol/MiHomeProtocol"
/usr/bin/codesign --force --sign - "$APP_DIR" >/dev/null

case "$MODE" in
  bundle)
    ;;
  run)
    /usr/bin/open -n "$APP_DIR"
    ;;
  --debug|debug)
    lldb -- "$APP_DIR/Contents/MacOS/$PRODUCT_NAME"
    ;;
  --verify|verify)
    /usr/bin/open -n "$APP_DIR"
    sleep 1
    pgrep -x "$PRODUCT_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [bundle|run|--debug|--verify]" >&2
    exit 2
    ;;
esac
