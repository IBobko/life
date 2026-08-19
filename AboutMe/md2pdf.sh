#!/usr/bin/env bash
#
# md2pdf.sh — конвертация Markdown в PDF.
#
# Особенность: включается расширение pandoc `hard_line_breaks`,
# поэтому КАЖДЫЙ перенос строки в .md становится переносом строки в PDF.
# Никаких двух пробелов в конце строки ставить не нужно.
#
# Использование:
#   ./md2pdf.sh input.md [output.pdf]
#
# Требуется: pandoc, google-chrome (или chromium).
# Если output.pdf не указан — берётся имя input.md с расширением .pdf.

set -euo pipefail

INPUT="${1:?Использование: $0 input.md [output.pdf]}"
OUTPUT="${2:-${INPUT%.md}.pdf}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSS="${MD2PDF_CSS:-$SCRIPT_DIR/md2pdf-style.css}"

TMP_HTML="$(mktemp --suffix=.html)"
trap 'rm -f "$TMP_HTML"' EXIT

# 1. Markdown -> HTML c hard_line_breaks (каждая строка = новая строка)
pandoc "$INPUT" \
  -f markdown+hard_line_breaks+smart \
  -t html5 \
  -s \
  -c "$CSS" \
  -o "$TMP_HTML"

# 2. HTML -> PDF через headless Chrome (печать как в браузере, с учётом @page CSS)
CHROME="$(command -v google-chrome || command -v chromium || command -v chromium-browser || true)"
if [ -z "$CHROME" ]; then
  echo "Ошибка: не найден google-chrome / chromium." >&2
  exit 1
fi

"$CHROME" \
  --headless \
  --disable-gpu \
  --no-sandbox \
  --print-to-pdf="$OUTPUT" \
  --no-pdf-header-footer \
  "file://$TMP_HTML" >/dev/null 2>&1

echo "Готово: $OUTPUT"
