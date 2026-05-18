# Организация вычислений с помощью Map / Filter / Reduce: общий принцип и специфика параллельной реализации обработки данных в Dask.Bag.

## TL;DR
**Map / Filter / Reduce** — фундаментальные операции функциональной обработки коллекций. **Map** $f: A\to B$ применяет функцию к каждому элементу. **Filter** $p: A\to\{T, F\}$ оставляет элементы по предикату. **Reduce** (fold) сворачивает коллекцию ассоциативным оператором $\oplus$ к одному значению. Эти операции **легко распараллеливаются**, особенно если $f, p$ чистые и $\oplus$ ассоциативна и коммутативна. **Dask.Bag** — Python-аналог: отложенно вычисляемая коллекция объектов на разделах (partitions), `bag.map(f)`, `bag.filter(p)`, `bag.fold(combine, binop, initial)`, `bag.foldby` (groupby+reduce), параллельное исполнение через task-граф.

## Развёрнуто

### Map / Filter / Reduce
Классическая «функциональная триада» обработки коллекций.

**Map** $\mathrm{map}(f, [x_1, \dots, x_n]) = [f(x_1), \dots, f(x_n)]$.
- Каждый элемент обрабатывается **независимо** → идеальная параллелизация.
- Чистая функция $f$ (без побочных эффектов) — критическое требование для безопасной параллелизации.

**Filter** $\mathrm{filter}(p, [x_1, \dots]) = [x_i : p(x_i)]$.
- Тоже независимая обработка; тривиально параллелится.

**Reduce / fold**:
$$\mathrm{reduce}(\oplus, [x_1, x_2, \dots, x_n], e) = (((e\oplus x_1)\oplus x_2)\oplus \dots)\oplus x_n.$$
Если $\oplus$ ассоциативна, можно балансированно: $((x_1\oplus x_2)\oplus(x_3\oplus x_4))\oplus\dots$ — параллельно, $O(\log n)$ глубины.

Если $\oplus$ ещё и коммутативна, порядок не важен — можно произвольно перемешивать.

### Композиция и оптимизации
- **Map fusion**: $\mathrm{map}(g)\circ \mathrm{map}(f) = \mathrm{map}(g\circ f)$ — слияние в один проход.
- **Filter fusion**: $\mathrm{filter}(p)\circ\mathrm{filter}(q) = \mathrm{filter}(\lambda x. p(x)\land q(x))$.
- **MapReduce**: типовая схема для big data. Map выдаёт пары (ключ, значение), shuffle группирует по ключу, reduce агрегирует. Пример: подсчёт слов.

### Параллельная реализация
Шаги:
1. Разбить коллекцию на $P$ **разделов (partitions)**.
2. Применить map / filter к каждому разделу независимо (на потоках/процессах/узлах).
3. Reduce — две фазы: локальная (внутри раздела) → глобальная (между разделами через дерево).

**Важно**:
- Чистые функции — без shared mutable state.
- Ассоциативность $\oplus$ — для корректной локальной агрегации.
- Сбалансированная нагрузка: одинаковый размер разделов или work stealing.

### Dask.Bag
Часть библиотеки **Dask** (Python). Аналог PySpark RDD для произвольных Python-объектов: ленивая, разделённая на partitions коллекция, выполняемая параллельно.

**Создание**:
```python
import dask.bag as db
b = db.from_sequence([1, 2, 3, 4, 5], npartitions=2)
b = db.read_text("logs/*.txt", blocksize="64MB")
```

**Основные методы**:
- `b.map(f)` — применить $f$ к каждому элементу. Ленивая — возвращает новый Bag.
- `b.filter(p)` — оставить элементы с $p(x)=$True.
- `b.flatten()` — расплющить (если каждый элемент — итерируемое).
- `b.distinct()` — уникальные.
- `b.fold(binop, initial=...)` или `b.reduction(perpartition, aggregate)` — reduce; нужны ассоциативность.
- `b.groupby(key)` — группировка (тяжёлая операция, требует shuffle).
- `b.foldby(key, binop, initial)` — groupby + reduce, эффективнее `groupby + map`.
- `b.compute()` — запустить вычисление и получить результат как обычный Python-объект.
- `b.to_dataframe()` — конвертация в `dask.dataframe`.

**Пример**:
```python
import dask.bag as db
b = db.read_text("logs/*.gz").map(json.loads)
counts = (b
    .filter(lambda r: r["status"] == 200)
    .map(lambda r: r["url"])
    .frequencies()
    .topk(10, key=lambda kv: kv[1]))
result = counts.compute()
```

Под капотом Dask строит **task-граф**: каждая partition — узел, операции — рёбра. Исполнение идёт через **scheduler** (threaded, multiprocessing или distributed).

### Сравнение с альтернативами
- **PySpark RDD/DataFrame**: похожая модель, но JVM-стек, развитая инфраструктура для больших кластеров.
- **multiprocessing.Pool.map**: проще, но без ленивости и сложного DAG.
- **Apache Beam**: универсальный API над разными движками.
- **MapReduce/Hadoop**: старый, медленный, исторически важный.
- **Pandas**: одиночный процесс, в памяти. Для больших данных — Dask DataFrame.

### Когда какой инструмент
- Структурированные таблицы (CSV/Parquet) → **Dask.DataFrame** или Spark.
- Произвольные объекты JSON/dict, текстовые логи, неструктурированные данные → **Dask.Bag**.
- Численные массивы → **Dask.Array** (аналог NumPy с partitions).

### Пример word count в Dask.Bag
```python
import dask.bag as db
b = db.read_text("books/*.txt")
words = b.str.lower().str.split().flatten()
counts = words.frequencies()
top10 = counts.topk(10, key=1)
print(top10.compute())
```

### Подводные камни
- `groupby` в Bag — full shuffle, дорогой; используйте `foldby`.
- При сложных объектах сериализация (pickle) — узкое место; передавайте простые типы.
- Map с side-effect ломает корректность — используйте только чистые функции.
- На малых данных Dask будет медленнее простого `for` из-за overhead планировщика.

См. `[[21 Модели параллельного программирования и их сочетаемость с архитектурами параллельных вычислительных]]`, `[[25 Организация Pandas DataFrame и организация индексации для DataFrame и Series]]`.
