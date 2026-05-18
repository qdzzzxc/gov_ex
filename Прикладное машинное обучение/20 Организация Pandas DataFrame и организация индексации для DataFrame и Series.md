# Организация Pandas DataFrame и организация индексации для DataFrame и Series. Операция GroupBy в Pandas DataFrame и реализация в ней подхода «разбиение, применение и объединение».

## TL;DR
**Pandas Series** — одномерный массив с **именованным индексом** (любого типа: int, str, datetime, MultiIndex). **DataFrame** — двумерный: набор `Series` (столбцов) с общим индексом строк и **индексом столбцов**. Внутри — массивы NumPy (по столбцам, в `BlockManager`/`ArrayManager`). **Индексация**: позиционная `.iloc`, по меткам `.loc`, булева, fancy. **GroupBy** реализует парадигму **split–apply–combine**: разбить по ключу, применить функцию (агрегацию/трансформацию/фильтрацию) к каждой группе, объединить. Ключевые методы: `agg`, `transform`, `apply`, `filter`. Эффективная реализация — векторизованные операции внутри групп.

## Развёрнуто

### Series
```python
import pandas as pd
s = pd.Series([10, 20, 30], index=['a', 'b', 'c'], name='score')
```
- `s.values` — NumPy-массив значений;
- `s.index` — объект `Index`;
- `s['a']` — доступ по метке;
- `s.iloc[0]` — позиционно;
- `s[s > 15]` — булева индексация;
- арифметика по индексу: `s1 + s2` выравнивает по меткам, `NaN` для несовпадающих.

### DataFrame
```python
df = pd.DataFrame({
    'name': ['Anna', 'Boris', 'Cyril'],
    'age':  [25, 30, 35],
    'city': ['Moscow', 'SPB', 'Moscow']
})
```
- `df.index` — индекс строк (по умолчанию `RangeIndex`);
- `df.columns` — индекс столбцов;
- `df.dtypes` — типы;
- `df.values` или `df.to_numpy()` — однородный массив (с приведением типов!);
- внутри Pandas хранит данные **по столбцам** в виде блоков NumPy (одного `dtype` на блок).

**Создание**:
- из dict (как выше);
- из списка списков с `columns`;
- `pd.read_csv/read_parquet/read_sql`.

### Индексация
Pandas различает **позицию** и **метку**:
- `df.iloc[0, 1]` — позиция (нулевая строка, первый столбец);
- `df.loc[0, 'age']` — метка строки и метка столбца;
- срезы по меткам **включают конец** (`df.loc[1:3]` — строки 1, 2, 3).

Смешанная и условная:
```python
df.loc[df['age'] > 27, ['name', 'city']]
df.iloc[[0, 2]]                       # fancy
df.set_index('name')                  # установить столбец как индекс
df.reset_index()
```

**MultiIndex** — иерархический индекс (несколько уровней):
```python
df = df.set_index(['city', 'name'])
df.loc['Moscow']                      # все строки города
df.loc[('Moscow', 'Anna')]
df.xs('Anna', level='name')           # cross-section по уровню
df.swaplevel().sort_index()
```

**Skinny vs wide**: `pivot`, `pivot_table`, `melt`, `stack`/`unstack` — преобразования между «длинным» и «широким» форматами через MultiIndex.

### Векторизованные операции
- арифметика и сравнения — поэлементно по меткам;
- `df['z'] = df['x'] + df['y']` — добавление столбца;
- `df.apply(f, axis=0/1)` — применить функцию к столбцу/строке;
- `df.applymap(f)` — поэлементно;
- `df['col'].map(d)` — замена значений по словарю или функции.

### GroupBy: split–apply–combine
**Идея** (Wickham, 2011):
1. **Split**: разбить DataFrame по значениям ключа.
2. **Apply**: применить функцию (агрегацию/трансформацию/фильтр) к каждой группе.
3. **Combine**: объединить результаты обратно.

```python
g = df.groupby('city')
```
Возвращает `DataFrameGroupBy`. `g.groups` — словарь `{key: indices}`. Не вычисляет ничего, пока не применишь операцию.

**Apply-варианты**:
- **Aggregation** (`agg`, `aggregate`): уменьшает группу до одной строки.
```python
g['age'].mean()
g.agg({'age': 'mean', 'name': 'count'})
g.agg(['mean', 'std', 'min', 'max'])
```
- **Transformation** (`transform`): возвращает результат той же длины, что и группа (например, нормализация внутри группы).
```python
df['age_z'] = g['age'].transform(lambda s: (s - s.mean()) / s.std())
```
- **Filtration** (`filter`): возвращает подмножество групп.
```python
g.filter(lambda d: len(d) >= 10)
```
- **Apply** — общий случай: вернёт что угодно (Series, DataFrame, скаляр), Pandas попытается собрать.

**Группировка по нескольким ключам**:
```python
df.groupby(['city', 'gender'])['salary'].mean()
```
Получаем Series с MultiIndex (city, gender).

**Custom aggregations**:
```python
def range_(s): return s.max() - s.min()
g['age'].agg(range_)
g.agg(min_age=('age', 'min'), avg_salary=('salary', 'mean'))   # NamedAgg
```

### Реализация split–apply–combine
- Pandas строит индекс групп (хеширование ключей + индексы);
- для встроенных агрегатов (`mean`, `sum`, `count`, `min/max`, `std`, `quantile`) — **C-реализация** в Cython, очень быстро;
- `apply` с произвольной Python-функцией медленнее, потому что Python-цикл по группам;
- результат собирается в DataFrame/Series с подходящим индексом (по ключам группировки).

### Альтернативы и расширения
- `pivot_table` — обобщённая агрегация в табличном виде:
```python
pd.pivot_table(df, index='city', columns='gender', values='salary', aggfunc='mean')
```
- `crosstab` — частоты по двум измерениям.
- `resample` — group-by по временным интервалам (для DatetimeIndex).
- `rolling`, `expanding` — оконные операции (не group-by, но related).

### Объединение DataFrame'ов
- `pd.concat([df1, df2], axis=0/1)` — конкатенация.
- `df1.merge(df2, on='key', how='inner|left|right|outer')` — SQL-стиль join.
- `df.join(other)` — по индексу.

### Пример сквозного потока
```python
import pandas as pd
df = pd.read_csv("sales.csv", parse_dates=["date"])
# Чистка
df = df.dropna(subset=["amount"])
df["amount"] = df["amount"].astype(float)
# Производные признаки
df["month"] = df["date"].dt.to_period("M")
# GroupBy
monthly = (
    df.groupby(["month", "region"])
      .agg(total_amount=("amount", "sum"),
           orders=("order_id", "count"),
           avg_check=("amount", "mean"))
      .reset_index()
)
# Pivot для удобства
pivot = monthly.pivot(index="month", columns="region", values="total_amount")
```

### Подводные камни
- `df['col']` возвращает Series; `df[['col']]` — DataFrame с одним столбцом. Разница важна.
- **SettingWithCopyWarning** — при цепочке индексаций на view легко модифицировать копию вместо оригинала; используйте `.loc` явно.
- При `apply` на больших данных — медленно. Лучше векторизованные операции / `agg` с встроенными.
- `groupby` с большими ключами требует памяти — рассмотрите `dask.dataframe` для больших данных.
- Типы данных: `object` обычно означает Python-объекты (строки, миксы) — медленно. Преобразуйте в `category`/специализированные типы.

См. `[[24 Организация массивов в NumPy хранение данных, принципы реализации операций с едиными исходными]]`, `[[22 Организация вычислений с помощью Map Filter Reduce общий принцип и специфика параллельной]]`.
