# Задача 4. Классификация Admitted / Not admitted по двум признакам.

## Условие
На рисунке — двумерное облако точек (оси примерно $30\ldots100$, по смыслу — баллы за два экзамена). Точки двух классов: **Admitted** (чёрные) и **Not admitted** (жёлтые); классы примерно разделимы прямой линией.

Предложить и обосновать вид модели для классификации, сопроводить графической интерпретацией решения на плоскости.

## Решение

### Программа минимум

```python
import numpy as np, matplotlib.pyplot as plt
from sklearn.linear_model import LogisticRegression
rng = np.random.default_rng(0)
X = np.r_[rng.normal([55,55], 12, (50,2)), rng.normal([75,75], 12, (50,2))]  # 2 класса
y = np.r_[np.zeros(50), np.ones(50)]
clf = LogisticRegression().fit(X, y)                                        # линейная граница
plt.scatter(X[:,0], X[:,1], c=y); print(clf.coef_, clf.intercept_)
plt.show()
```

### Полное решение

### Идея и выбор модели
- Признаков всего 2, классов — 2, граница на глаз почти линейная — значит, имеет смысл взять **линейный классификатор**.
- Базовый выбор — **логистическая регрессия (logistic regression)**:
$$P(y=1 \mid x) = \sigma(w^\top x + b),\qquad \sigma(z) = \frac{1}{1 + e^{-z}}.$$
Граница принятия решения — гиперплоскость $w^\top x + b = 0$ (на плоскости — прямая).
- Параметры оцениваются по максимуму правдоподобия (минимизация лог-потерь). Для двух признаков задача гладкая выпуклая — сходится за десятки итераций.
- Альтернативы: линейный SVM (тот же тип границы, но «макс. зазор»), LDA. Все дадут практически ту же прямую.
- Если бы граница была явно изогнутой — добавляем квадратичные признаки $x_1^2, x_2^2, x_1 x_2$ или берём ядровой SVM / решающее дерево.

### Код
```python
import numpy as np
import matplotlib.pyplot as plt
from sklearn.linear_model import LogisticRegression

rng = np.random.default_rng(0)
n = 50
X0 = rng.normal([55, 55], 12, size=(n, 2))   # Not admitted
X1 = rng.normal([75, 75], 12, size=(n, 2))   # Admitted
X = np.vstack([X0, X1]); y = np.r_[np.zeros(n), np.ones(n)]

clf = LogisticRegression().fit(X, y)
w1, w2 = clf.coef_[0]; b = clf.intercept_[0]
print(f"граница: {w1:.3f}·x1 + {w2:.3f}·x2 + {b:.3f} = 0")
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

### Прогон
```
граница: 0.115·x1 + 0.119·x2 + -15.297 = 0
accuracy: 0.850
```

### Ответ
- **Модель:** логистическая регрессия (линейный классификатор).
- **Решающее правило:** $\hat y = 1 \iff 0{,}115\,x_1 + 0{,}119\,x_2 - 15{,}3 > 0$, иначе $\hat y = 0$.
- **Графическая интерпретация:** на плоскости $(x_1, x_2)$ прямая $0{,}115\,x_1 + 0{,}119\,x_2 = 15{,}3$ делит её на «допущен» / «не допущен»; цветовой фон — вероятность $P(\text{admitted})$.

### Замечания
- Если классы сильно несбалансированы — добавлять `class_weight='balanced'` или работать с порогом отсечения, не равным 0,5.
- Признаки разной шкалы стоит нормировать (StandardScaler) — здесь шкалы одинаковые, и так норм.
- Качество оценивать по hold-out / CV, не по обучению (на маленьком наборе будет оптимистично).
- См. близкие задачи: [[02 Метрики мультиклассовой классификации диагностика болезни]], [[03 Решающее дерево для классификации точек на плоскости]].
