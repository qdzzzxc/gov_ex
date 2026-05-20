# Задача 5. Matplotlib: гистограммы распределений с теоретическими плотностями.

## Условие
Используя функционал `numpy` и `matplotlib`, сгенерируйте по 10000 случайных величин с нормальным, равномерным и экспоненциальным распределениями и постройте гистограммы этих распределений, наложив на них теоретические графики плотностей распределения вероятностей. Параметры распределений выбрать произвольно. Решение предложить в виде программного кода.

## Решение

### Программа минимум

```python
import numpy as np, matplotlib.pyplot as plt
x = np.linspace(-4, 4, 300); rng = np.random.default_rng(1)
data = [rng.normal(0,1,10000), rng.uniform(0,1,10000), rng.exponential(1,10000)]  # выборки
pdfs = [np.exp(-x*x/2)/np.sqrt(2*np.pi), (x>=0)&(x<=1), np.exp(-x)*(x>=0)]       # плотности
for i in range(3):
    plt.figure(); plt.hist(data[i], bins=50, density=True, alpha=.5)             # гистограмма
    plt.plot(x, pdfs[i])                                                         # теория
plt.show()
```

### Полное решение

### Идея
По 10 000 случайных величин для трёх распределений: $\mathcal{N}(0, 1)$, $U(0, 1)$, $\mathrm{Exp}(\lambda = 1)$. На каждой картинке — гистограмма с `density=True` (площадь = 1) и поверх — теоретическая плотность $p(x)$.

### Код

```python
import numpy as np, matplotlib.pyplot as plt
from scipy import stats

rng = np.random.default_rng(2026)
n = 10_000
samples = {
    "Normal(0,1)":  (rng.normal(0, 1, n),     stats.norm(0, 1).pdf,    np.linspace(-4, 4, 200)),
    "Uniform(0,1)": (rng.uniform(0, 1, n),    stats.uniform(0, 1).pdf, np.linspace(0,  1, 200)),
    "Exp(λ=1)":     (rng.exponential(1, n),   stats.expon(scale=1).pdf, np.linspace(0, 8, 200)),
}

fig, axs = plt.subplots(1, 3, figsize=(12, 3))
for ax, (name, (data, pdf, xs)) in zip(axs, samples.items()):
    ax.hist(data, bins=50, density=True, alpha=0.6)
    ax.plot(xs, pdf(xs), 'r-', lw=1.5, label="теор. плотность")
    ax.set_title(name); ax.legend()
plt.tight_layout(); plt.show()
```

### Прогон
Эмпирические моменты на $n = 10\,000$:
```
Normal(0,1)    mean=-0.002  var=1.011
Uniform(0,1)   mean= 0.497  var=0.083    (теор: 1/2, 1/12 ≈ 0.083)
Exp(λ=1)       mean= 0.983  var=0.952    (теор: 1, 1)
```

### Замечания
- `density=True` нормирует гистограмму так, что её площадь равна $1$ — поэтому на ней корректно накладывать теоретическую плотность.
- Для `expon` в `scipy` параметризация — `scale = 1/λ`, поэтому `Exp(1)` — это `stats.expon(scale=1)`.
- Число корзин: эвристика Стёрджеса $\lceil \log_2 n \rceil + 1$ или Фридмана-Дьякониса; для $n = 10\,000$ 50 корзин — разумный компромисс.
