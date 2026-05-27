#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

OUT=$(mktemp)
shift_headings() { awk '/^```/ {f=!f; print; next} !f && /^#/ {print "#" $0; next} {print}' "$1"; }
append_block() { printf '# %s\n\n' "$2" >> "$OUT"; for fp in "$1"/*.md; do shift_headings "$fp" >> "$OUT"; printf '\n\n' >> "$OUT"; done; }

printf '# Главные формулы\n\n' >> "$OUT"; shift_headings "Главные формулы.md" >> "$OUT"; printf '\n\n' >> "$OUT"
append_block "Прикладная математика и информатика" "Прикладная математика и информатика"
append_block "Прикладное машинное обучение"        "Прикладное машинное обучение"
for theme in "Практико-ориентированные задания"/*/; do
  append_block "$theme" "Задачи · $(basename "$theme")"
done

pandoc "$OUT" \
  -f 'markdown+wikilinks_title_after_pipe+tex_math_dollars+lists_without_preceding_blankline-blank_before_header-blank_before_blockquote' \
  -t html5 -s --toc --toc-depth=2 --mathml \
  --metadata title="Подготовка к ГИА — вопросы и задачи" --metadata lang=ru \
  -c gia_style.css --embed-resources \
  -o "ГИА.html"

rm -f "$OUT"
echo "Готово: ГИА.html"
