# Задача 4. Классификация Admitted / Not admitted по двум признакам.

## Условие
![[Pasted image 20260526211612.png]]

Предложить и обосновать вид модели для классификации, сопроводить графической интерпретацией решения на плоскости.
## Решение
## Идея и выбор модели
- Признаков 2, классов 2. Граница на картинке **изогнутая** — жёлтые точки (Not admitted) образуют дугу снизу-слева, чёрные (Admitted) заполняют верхнюю-правую часть. Линейный классификатор не подойдёт — диагональная прямая будет ошибаться в углах дуги.
- Базовый выбор — **логистическая регрессия с полиномиальными признаками 2-й степени**. К исходным $x_1, x_2$ добавляем $x_1^2, x_2^2, x_1 x_2$: $$P(y=1 \mid x) = \sigma(w_1 x_1 + w_2 x_2 + w_3 x_1^2 + w_4 x_2^2 + w_5 x_1 x_2 + b)$$ Модель остаётся линейной по параметрам (задача оптимизации выпуклая), но граница принятия решения в координатах $(x_1, x_2)$ — кривая второго порядка (эллипс, гипербола, парабола). Подходит под форму на картинке.
- Альтернативы: SVM с RBF-ядром (гибче, менее интерпретируемо), решающее дерево / случайный лес (кусочно-постоянные границы). Для двух признаков и сотни объектов полиномиальной логистики достаточно.
- Чисто линейная модель оставляется как бейзлайн для сравнения accuracy.
## Код

```python
import numpy as np
import matplotlib.pyplot as plt
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import PolynomialFeatures
from sklearn.pipeline import make_pipeline

rng = np.random.default_rng(0)
n = 50
X0 = rng.normal([55, 55], 12, size=(n, 2))
X1 = rng.normal([75, 75], 12, size=(n, 2))
X = np.vstack([X0, X1])
y = np.r_[np.zeros(n), np.ones(n)]

clf = make_pipeline(PolynomialFeatures(degree=2), LogisticRegression(max_iter=1000))
clf.fit(X, y)
print("accuracy:", clf.score(X, y))

xx, yy = np.meshgrid(np.linspace(20, 110, 200), np.linspace(20, 110, 200))
Z = clf.predict_proba(np.c_[xx.ravel(), yy.ravel()])[:, 1].reshape(xx.shape)
plt.contourf(xx, yy, Z, levels=20, alpha=0.3, cmap="RdYlBu_r")
plt.contour(xx, yy, Z, levels=[0.5], colors="k", linewidths=2)
plt.scatter(*X0.T, c="gold", edgecolor="k", label="Not admitted")
plt.scatter(*X1.T, c="black", label="Admitted")
plt.xlabel("Exam 1"); plt.ylabel("Exam 2"); plt.legend()
plt.show()
```

## Ответ
- Модель: логистическая регрессия с полиномиальными признаками 2-й степени.
- Решающее правило: $\hat y = 1 \iff \sigma(\sum w_i \phi_i(x) + b) > 0{,}5$, где $\phi_i$ — исходные и квадратичные признаки.
- Графическая интерпретация: граница на плоскости $(x_1, x_2)$ — кривая второго порядка, разделяющая «допущен» и «не допущен». Цветовой фон — вероятность $P(\text{admitted})$.
## Замечания
- Признаки разной шкалы стоит нормировать перед `PolynomialFeatures` — здесь шкалы одинаковые.