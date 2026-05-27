# Сборка единого HTML для чтения с телефона

Все вопросы и задачи собираются в один самодостаточный файл **`ГИА.html`** —
открывается в любом браузере (в т.ч. на телефоне) **офлайн**, с оглавлением,
поиском по Ctrl+F и формулами.

## Быстрый запуск

```bash
bash build_html.sh
```

(скрипт ниже; результат — `ГИА.html` в корне)

## Что внутри и почему именно так

**Рендер формул — MathML (`--mathml`), а не MathJax.**
MathJax грузит JS с CDN → без интернета формулы не отрисовываются. MathML
встраивается в HTML на этапе сборки и рендерится самим браузером офлайн.

**Заголовки сдвигаются на уровень вниз awk'ом.**
В файлах H1 (`#`) — формулировка вопроса. Чтобы сделать двухуровневое оглавление
(раздел → вопрос), каждый файл сдвигается `#`→`##`, а раздел добавляется как `#`.
Сдвиг учитывает code-блоки (` ``` `), иначе `#`-комментарии в Python поехали бы.

**Флаги pandoc, без которых ломается разметка Obsidian:**
- `-blank_before_header` — Obsidian не требует пустой строки перед `##`/`###`,
  pandoc по умолчанию требует и иначе считает заголовок обычным текстом.
- `lists_without_preceding_blankline` — то же для списков сразу после абзаца.
- `-blank_before_blockquote` — то же для цитат.
- `+tex_math_dollars` — формулы в `$...$` / `$$...$$`.
- `+wikilinks_title_after_pipe` — `[[ссылки]]` Obsidian парсятся как ссылки.

**`--embed-resources`** — инлайнит CSS (`gia_style.css`), файл остаётся один.
CSS добавляет переносы заголовков (`text-wrap: balance`), переносы по слогам для
русского, ограничение ширины колонки и тёмную тему.

## Скрипт `build_html.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

OUT=$(mktemp)
shift_headings() { awk '/^```/ {f=!f; print; next} !f && /^#/ {print "#" $0; next} {print}' "$1"; }
append_block() { printf '# %s\n\n' "$2" >> "$OUT"; for fp in "$1"/*.md; do shift_headings "$fp" >> "$OUT"; printf '\n\n' >> "$OUT"; done; }

# Порядок разделов
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
```

Требуется `pandoc` (проверено на 3.1.3). CSS — в `gia_style.css`.

---

# Альтернатива: Quartz (полноценный сайт)

В папке `quartz/` развёрнут [Quartz 5](https://quartz.jzhao.xyz/) — статический
генератор сайта с обсидиановским рендером (кликабельные `[[ссылки]]`, граф связей,
поиск, Explorer по папкам). Контент берётся из vault через симлинки в
`quartz/content/`. Требует Node ≥ 22.

```bash
cd quartz
nvm use 22                      # node 18 по умолчанию не подойдёт
npx quartz build --serve        # локальный просмотр на http://localhost:8080
```

Для деплоя на GitHub Pages — `npx quartz sync` (см. docs Quartz).
