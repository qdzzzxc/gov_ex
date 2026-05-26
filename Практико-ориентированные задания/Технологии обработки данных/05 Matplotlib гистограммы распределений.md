# Задача 5. Matplotlib: гистограммы распределений с теоретическими плотностями.

## Условие
Используя функционал `numpy` и `matplotlib`, сгенерируйте по 10000 случайных величин с нормальным, равномерным и экспоненциальным распределениями и постройте гистограммы этих распределений, наложив на них теоретические графики плотностей распределения вероятностей. Параметры распределений выбрать произвольно. Решение предложить в виде программного кода.

## Решение
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
### Замечания
- `density=True` нормирует гистограмму так, что её площадь равна $1$ — поэтому на ней корректно накладывать теоретическую плотность.
- Для `expon` в `scipy` параметризация — `scale = 1/λ`, поэтому `Exp(1)` — это `stats.expon(scale=1)`.
