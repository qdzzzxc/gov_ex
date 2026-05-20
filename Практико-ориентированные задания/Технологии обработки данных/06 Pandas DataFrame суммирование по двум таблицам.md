# Задача 6. Pandas: суммирование продаж и отчётов по двум датафреймам.

## Условие
При помощи библиотеки `pandas` создать два датафрейма с индексами:
- первый: `'Moscow', 'Tula', 'Yaroslavl', 'Tver'`;
- второй: `'Moscow', 'Tula', 'Volgograd', 'Novgorod'`,

и случайными значениями в столбцах `report` (от 1 до 10) и `sales` (от 100 до 1000).

**Требуется:** написать программный код расчёта суммы продаж и суммарного количества отчётов по двум таблицам.

## Решение

### Программа минимум

```python
import numpy as np, pandas as pd
rng = np.random.default_rng(1)
df1 = pd.DataFrame({"report": rng.integers(1, 11, 4), "sales": rng.integers(100, 1001, 4)},
                   index=["Moscow","Tula","Yaroslavl","Tver"])
df2 = pd.DataFrame({"report": rng.integers(1, 11, 4), "sales": rng.integers(100, 1001, 4)},
                   index=["Moscow","Tula","Volgograd","Novgorod"])
total = df1.add(df2, fill_value=0).astype(int)               # сумма по индексам
print(total, total.sum(), sep="\n")
```

### Полное решение

### Идея
- Создаём два датафрейма с заданными индексами (городами) и случайными значениями `report` ∈ $[1, 10]$, `sales` ∈ $[100, 1000]$.
- `df1.add(df2, fill_value=0)` суммирует по совпадающим индексам и подставляет значение из второго DF (или 0) для несовпадающих.
- Итог — `.sum()` по столбцам.

### Код

```python
import numpy as np, pandas as pd

rng = np.random.default_rng(42)
df1 = pd.DataFrame({
    "report": rng.integers(1, 11,   4),
    "sales":  rng.integers(100, 1001, 4),
}, index=["Moscow", "Tula", "Yaroslavl", "Tver"])

df2 = pd.DataFrame({
    "report": rng.integers(1, 11,   4),
    "sales":  rng.integers(100, 1001, 4),
}, index=["Moscow", "Tula", "Volgograd", "Novgorod"])

total = df1.add(df2, fill_value=0).astype(int)
print(total)
print(f"\nИтого:  sales = {total['sales'].sum()},  reports = {total['report'].sum()}")
```

### Прогон
```
df1:                           df2:
            report  sales                  report  sales
Moscow         1    490        Moscow         3    762
Tula           8    873        Tula           1    785
Yaroslavl      7    177        Volgograd      6    746
Tver           5    728        Novgorod      10    808

total (по индексам):
            report  sales
Moscow         4   1252
Novgorod      10    808
Tula           9   1658
Tver           5    728
Volgograd      6    746
Yaroslavl      7    177

Итого:  sales = 5369,  reports = 41
```

### Замечания
- Ключевой момент: `add(..., fill_value=0)` корректно обрабатывает несовпадающие индексы, в отличие от обычного `df1 + df2`, который вернул бы `NaN` в строках, отсутствующих в одной из таблиц.
- `.astype(int)` нужен потому, что `add` приводит к `float`, чтобы поддержать `NaN`.
- Альтернатива через `concat`: `pd.concat([df1, df2]).groupby(level=0).sum()` — тот же результат.
