# Формат XML и модель DOM: общая характеристика, пример описания данных в XML и DOM, работа с ними с помощью библиотеки BeautifulSoup.

## TL;DR
**XML (eXtensible Markup Language)** — текстовый разметочный формат для структурированных данных: элементы, атрибуты, вложенность, обязательная корректность тегов. **DOM (Document Object Model)** — древовидная объектная модель: документ — корень, элементы — внутренние узлы, текст и атрибуты — листья. Загруженный документ полностью держится в памяти, поддерживает навигацию (родитель, дети, соседи), модификацию, поиск (XPath, CSS-селекторы). **BeautifulSoup** — Python-библиотека для разбора HTML/XML; над DOM-моделью даёт удобные методы `find/find_all`, `.parent`, `.children`, CSS-`select`. Хороша для парсинга «грязного» HTML.

## Развёрнуто

### XML — общая характеристика
- Строгая иерархическая структура: каждое начало `<tag>` имеет конец `</tag>` (или самозакрывающееся `<tag/>`).
- **Элементы** содержат текст и/или другие элементы. **Атрибуты** в открывающем теге: `<book id="1" lang="ru">`.
- **Корневой элемент** один.
- Декларация: `<?xml version="1.0" encoding="UTF-8"?>`.
- Поддержка namespace (`xmlns:prefix=...`), DTD/XSD-схем для валидации, CDATA-секций для вставки текста с спецсимволами.
- Регистрозависимость, обязательное экранирование `<, >, &, ", '`.

XML самодокументируем (теги осмысленны), легко расширяется, читается человеком, хотя многословен. Используется в SOAP, RSS, SVG, конфигах, документообороте, обмене данными между системами.

### Пример XML
```xml
<?xml version="1.0" encoding="UTF-8"?>
<library>
  <book id="1" lang="ru">
    <title>Война и мир</title>
    <author>Толстой Л. Н.</author>
    <year>1869</year>
  </book>
  <book id="2" lang="en">
    <title>1984</title>
    <author>Orwell G.</author>
    <year>1949</year>
  </book>
</library>
```

### Модель DOM
**DOM** — стандартный API для доступа к XML/HTML как к дереву объектов.

**Узлы** (Node):
- `Document` — корень.
- `Element` — теги.
- `Attr` — атрибуты.
- `Text` — текст внутри элементов.
- `Comment`, `CDATASection` и др.

**Свойства/методы навигации**:
- `parentNode`, `childNodes`, `firstChild`, `nextSibling`;
- `getElementById`, `getElementsByTagName`, `getElementsByClassName`;
- `querySelector`/`querySelectorAll` — CSS-селекторы;
- `getAttribute`, `setAttribute`.

**Поиск через XPath**: `/library/book[@lang='ru']/title` — выражение пути.

**Особенности**:
- Документ загружается **полностью в память** — ограничение для очень больших файлов.
- Альтернатива — потоковый парсер **SAX/StAX** (события open/close/text).
- В Python для DOM/потокового парсинга используются `xml.etree.ElementTree`, `lxml`, `xml.dom.minidom`, `xml.sax`.

### Дерево DOM для примера
```
Document
└── library (Element)
    ├── book id=1 lang=ru (Element)
    │   ├── title → "Война и мир" (Text)
    │   ├── author → "Толстой Л. Н."
    │   └── year → "1869"
    └── book id=2 lang=en
        ├── title → "1984"
        ├── author → "Orwell G."
        └── year → "1949"
```

### BeautifulSoup
Библиотека Python для парсинга HTML и XML. Устойчива к битой разметке, удобный API.

**Установка и парсинг**:
```python
from bs4 import BeautifulSoup
with open("library.xml", encoding="utf-8") as f:
    soup = BeautifulSoup(f, "xml")  # или "lxml-xml", "html.parser"
```

**Навигация**:
```python
soup.library                       # первый <library>
soup.library.book                  # первый <book>
soup.find("book", id="1")          # поиск по тегу+атрибутам
soup.find_all("book")              # все <book>
soup.select("book[lang=ru] title") # CSS-селектор
for book in soup.find_all("book"):
    print(book["id"], book.title.text)
```

**Извлечение данных**:
- `tag.name` — имя.
- `tag["attr"]` — значение атрибута; `tag.get("attr")` — с дефолтом.
- `tag.attrs` — словарь атрибутов.
- `tag.text` (или `.get_text()`) — конкатенация всего текста потомков.
- `tag.string` — текст, если ровно один Text-потомок.
- `tag.contents`, `tag.children`, `tag.descendants` — потомки.
- `tag.parent`, `tag.parents`, `tag.next_sibling`, `tag.previous_sibling`.

**Модификация**:
```python
tag["lang"] = "fr"
tag.string = "новый текст"
tag.append(soup.new_tag("note", text="комментарий"))
tag.decompose()  # удалить
```

**Сохранение**:
```python
print(soup.prettify())
```

### Пример: извлечение данных
```python
from bs4 import BeautifulSoup
xml_text = open("library.xml", encoding="utf-8").read()
soup = BeautifulSoup(xml_text, "xml")
russian_books = [
    {"id": b["id"], "title": b.title.text, "author": b.author.text}
    for b in soup.find_all("book", lang="ru")
]
```

### Когда использовать что
- Парсинг **HTML** (особенно битого, реальных страниц): BeautifulSoup + парсер html.parser/lxml.
- Парсинг **XML** строгого, со схемой: `lxml.etree` (быстрее, поддерживает XPath/XSLT/XSD) или `xml.etree.ElementTree`.
- **Очень большие** XML: SAX/iterparse — потоковая обработка без загрузки в память.
- Web scraping: BeautifulSoup + Requests; для динамики — Selenium/Playwright.

### Сравнение XML и JSON
- XML: атрибуты, namespace, схемы (XSD), вальядация, многословие.
- JSON: проще, легче, нативен для JS, преобладает в REST API.
- В современных API JSON чаще, XML остаётся в legacy, документообороте и где нужна строгая валидация.

### Подводные камни
- BeautifulSoup сам **не поддерживает XPath** — нужен `lxml.etree`.
- Парсер `html.parser` бывает менее устойчив к ошибкам, чем `lxml`/`html5lib` — проверьте, какой используете.
- При работе с большими файлами BeautifulSoup съест много памяти; используйте `iterparse`.
- Кодировки: всегда указывайте при чтении (`encoding="utf-8"`).
- При экспорте обратно в строку могут «пропасть» декларации/комментарии — проверяйте `prettify`.
