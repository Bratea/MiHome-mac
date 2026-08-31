#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="MiHome"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON_BIN="${PYTHON_BIN:-python3}"
VENV_DIR="$ROOT_DIR/.venv"
PYTHON="$VENV_DIR/bin/python"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
VERSION="$(sed -n 's/__version__ = "\(.*\)"/\1/p' "$ROOT_DIR/app/__init__.py" | head -n 1)"

cd "$ROOT_DIR"

if [[ ! -x "$PYTHON" ]]; then
  "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

"$PYTHON" -m pip install --upgrade pip
"$PYTHON" -m pip install -e . pyinstaller

case "$MODE" in
  run|--verify|verify|--debug|debug|--logs|logs|--telemetry|telemetry) ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

"$PYTHON" -m PyInstaller \
  --noconfirm \
  --clean \
  --windowed \
  --name "$APP_NAME" \
  --osx-bundle-identifier "com.mihome.mac" \
  --icon "$ROOT_DIR/resources/MiHome.icns" \
  --collect-all qtawesome \
  --collect-submodules mijiaAPI \
  --collect-data app \
  --distpath "$ROOT_DIR/dist" \
  --workpath "$ROOT_DIR/build/pyinstaller" \
  --specpath "$ROOT_DIR/build" \
  run.py

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP_BUNDLE/Contents/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $VERSION" "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$APP_BUNDLE/Contents/Info.plist"
codesign --force --deep --sign - "$APP_BUNDLE"

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --verify|verify)
    open_app
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    ;;
esac
