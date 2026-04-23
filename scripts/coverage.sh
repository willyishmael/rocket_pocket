#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RAW_LCOV="coverage/lcov.info"
CLEAN_LCOV="coverage/lcov.cleaned.info"
HTML_DIR="coverage/html"

echo "Running Flutter tests with coverage..."
flutter test --coverage

if [[ ! -f "$RAW_LCOV" ]]; then
  echo "Coverage file not found at $RAW_LCOV"
  exit 1
fi

echo "Filtering generated files from coverage report..."
awk '
  /^SF:/ {
    path = substr($0, 4)
    skip = (path ~ /\.g\.dart$/) ||
           (path ~ /\.freezed\.dart$/) ||
           (path ~ /\/generated\//) ||
           (path ~ /\/test\//)
  }
  { if (!skip) print }
' "$RAW_LCOV" > "$CLEAN_LCOV"

echo "Coverage summary (filtered):"
awk -F: '
  BEGIN { lf = 0; lh = 0 }
  /^LF:/ { lf += $2 }
  /^LH:/ { lh += $2 }
  END {
    if (lf > 0) {
      printf("covered=%d total=%d coverage=%.2f%%\n", lh, lf, (lh/lf) * 100)
    } else {
      print "No coverage data"
      exit 1
    }
  }
' "$CLEAN_LCOV"

if [[ "${1:-}" == "--html" ]]; then
  if command -v genhtml >/dev/null 2>&1; then
    echo "Generating HTML report at $HTML_DIR..."
    genhtml "$CLEAN_LCOV" -o "$HTML_DIR" >/dev/null
    echo "HTML report ready: $HTML_DIR/index.html"
  else
    echo "genhtml is not installed. Install lcov via: brew install lcov"
    exit 1
  fi
fi
