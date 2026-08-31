#!/usr/bin/env bash
set -euo pipefail

NATIVE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_ROOT="$(cd "$NATIVE_ROOT/.." && pwd)"
PYTHON="$PROJECT_ROOT/.venv/bin/python"
OUTPUT_ROOT="$NATIVE_ROOT/.build/protocol"

test -x "$PYTHON"
"$PYTHON" -m PyInstaller \
  --noconfirm \
  --clean \
  --onedir \
  --name MiHomeProtocol \
  --paths "$PROJECT_ROOT" \
  --distpath "$OUTPUT_ROOT/dist" \
  --workpath "$OUTPUT_ROOT/work" \
  --specpath "$OUTPUT_ROOT/spec" \
  "$PROJECT_ROOT/script/native_bridge.py"
