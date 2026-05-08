Dưới đây là phiên bản đã thêm **MLflow** và tách thành từng cell để bạn chạy notebook dễ hơn. Tôi bám theo flow trong đoạn code bạn gửi , nhưng chỉnh lại để:

* có **1 cell setup**
* có **1 cell train + GridSearchCV**
* có **1 cell threshold tuning**
* có **1 cell final evaluation**
* mỗi bước đều log vào **MLflow**
* tách rõ `best model run` và `threshold tuning run`

---

## Cell 1 — Import và setup

```python
import numpy as np
import pandas as pd
import mlflow
import mlflow.sklearn

from sklearn.model_selection import (
    train_test_split,
    StratifiedKFold,
    GridSearchCV,
    cross_val_predict
)
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    precision_score,
    recall_score,
    f1_score,
    classification_report,
    confusion_matrix,
    roc_auc_score,
    accuracy_score
)
```

---

## Cell 2 — Input data + split hold-out test

```python
# =========================================================
# 1. INPUT
# =========================================================
# Giả sử bạn đã có:
# X = feature matrix
# y = target

# Ví dụ:
# X = df_engineered[best_features]
# y = df_engineered[target_col]

# =========================================================
# 2. HOLD-OUT TEST SET
# =========================================================
X_train, X_test, y_train, y_test = train_test_split(
    X,
    y,
    test_size=0.15,
    stratify=y,
    random_state=42
)

print("Train shape:", X_train.shape)
print("Test shape :", X_test.shape)
print("Train target distribution:", pd.Series(y_train).value_counts(normalize=True).to_dict())
print("Test target distribution :", pd.Series(y_test).value_counts(normalize=True).to_dict())
```

---

## Cell 3 — Define CV + MLflow experiment

```python
# =========================================================
# 3. DEFINE CV SPLITTER
# =========================================================
cv = StratifiedKFold(
    n_splits=5,
    shuffle=True,
    random_state=42
)

# =========================================================
# 4. SET MLFLOW EXPERIMENT
# =========================================================
mlflow.set_experiment("home_credit_logistic_pipeline")

print("MLflow experiment is ready.")
```

---

## Cell 4 — Train + hyperparameter tuning với GridSearchCV

```python
# =========================================================
# 5. HYPERPARAMETER TUNING
# =========================================================
param_grid = [
    {
        "solver": ["lbfgs"],
        "penalty": ["l2"],
        "C": [0.01, 0.1, 1.0, 10.0],
        "class_weight": [None, "balanced"],
        "max_iter": [1000]
    },
    {
        "solver": ["liblinear"],
        "penalty": ["l1", "l2"],
        "C": [0.01, 0.1, 1.0, 10.0],
        "class_weight": [None, "balanced"],
        "max_iter": [1000]
    },
    {
        "solver": ["saga"],
        "penalty": ["l1", "l2"],
        "C": [0.01, 0.1, 1.0, 10.0],
        "class_weight": [None, "balanced"],
        "max_iter": [1000]
    }
]

base_model = LogisticRegression(random_state=42)

with mlflow.start_run(run_name="logistic_gridsearch_training") as train_run:
    train_run_id = train_run.info.run_id
    
    mlflow.log_param("test_size", 0.15)
    mlflow.log_param("cv_n_splits", 5)
    mlflow.log_param("cv_shuffle", True)
    mlflow.log_param("cv_random_state", 42)
    mlflow.log_param("scoring", "f1")
    mlflow.log_param("model_type", "LogisticRegression")

    grid = GridSearchCV(
        estimator=base_model,
        param_grid=param_grid,
        scoring="f1",
        cv=cv,
        n_jobs=-1,
        verbose=1,
        refit=True,
        return_train_score=True
    )

    grid.fit(X_train, y_train)

    best_model = grid.best_estimator_

    print("\n=== BEST HYPERPARAMETERS ===")
    print("Best params :", grid.best_params_)
    print("Best CV F1  :", round(grid.best_score_, 6))

    # log best params
    for k, v in grid.best_params_.items():
        mlflow.log_param(f"best_{k}", v)

    mlflow.log_metric("best_cv_f1", grid.best_score_)

    # log model
    mlflow.sklearn.log_model(best_model, artifact_path="model")

print("Train run_id:", train_run_id)
```

---

## Cell 5 — Xem bảng kết quả tuning (optional nhưng rất nên có)

```python
cv_results_df = pd.DataFrame(grid.cv_results_)

display(
    cv_results_df[
        [
            "rank_test_score",
            "mean_test_score",
            "std_test_score",
            "param_solver",
            "param_penalty",
            "param_C",
            "param_class_weight",
            "param_max_iter"
        ]
    ].sort_values("rank_test_score").head(10)
)
```

---

## Cell 6 — Threshold tuning bằng OOF probabilities

```python
# =========================================================
# 6. OOF PROBABILITIES FOR THRESHOLD TUNING
# =========================================================
oof_prob = cross_val_predict(
    estimator=best_model,
    X=X_train,
    y=y_train,
    cv=cv,
    method="predict_proba",
    n_jobs=-1,
    verbose=0
)[:, 1]

thresholds = np.arange(0.05, 0.96, 0.01)
threshold_results = []

with mlflow.start_run(run_name="logistic_threshold_tuning", nested=False) as threshold_run:
    threshold_run_id = threshold_run.info.run_id

    mlflow.log_param("source_train_run_id", train_run_id)
    mlflow.log_param("threshold_start", 0.05)
    mlflow.log_param("threshold_end", 0.95)
    mlflow.log_param("threshold_step", 0.01)
    mlflow.log_param("threshold_selection_metric", "f1")

    for t in thresholds:
        oof_pred = (oof_prob >= t).astype(int)

        precision = precision_score(y_train, oof_pred, zero_division=0)
        recall = recall_score(y_train, oof_pred, zero_division=0)
        f1 = f1_score(y_train, oof_pred, zero_division=0)
        acc = accuracy_score(y_train, oof_pred)

        threshold_results.append({
            "threshold": round(float(t), 2),
            "precision": precision,
            "recall": recall,
            "f1": f1,
            "accuracy": acc
        })

    threshold_df = pd.DataFrame(threshold_results)

    best_row_f1 = threshold_df.loc[threshold_df["f1"].idxmax()]
    best_threshold_f1 = float(best_row_f1["threshold"])

    best_row_recall = threshold_df.loc[threshold_df["recall"].idxmax()]
    best_threshold_recall = float(best_row_recall["threshold"])

    selected_threshold = best_threshold_f1

    mlflow.log_metric("best_threshold_by_f1", best_threshold_f1)
    mlflow.log_metric("best_f1_at_selected_threshold", best_row_f1["f1"])
    mlflow.log_metric("precision_at_selected_threshold", best_row_f1["precision"])
    mlflow.log_metric("recall_at_selected_threshold", best_row_f1["recall"])
    mlflow.log_metric("accuracy_at_selected_threshold", best_row_f1["accuracy"])

print("Threshold run_id:", threshold_run_id)

print("\n=== BEST THRESHOLD BY F1 ===")
print(best_row_f1)

print("\n=== BEST THRESHOLD BY RECALL ===")
print(best_row_recall)

print("\nSelected threshold:", selected_threshold)
```

---

## Cell 7 — Xem top threshold

```python
display(threshold_df.sort_values("f1", ascending=False).head(10))
```

---

## Cell 8 — Final fit trên full train set

```python
# =========================================================
# 7. FINAL FIT ON FULL TRAIN SET
# =========================================================
final_model = LogisticRegression(**grid.best_params_, random_state=42)
final_model.fit(X_train, y_train)

print("Final model trained on full X_train.")
```

---

## Cell 9 — Final evaluation trên hold-out test set

```python
# =========================================================
# 8. FINAL TEST EVALUATION
# =========================================================
with mlflow.start_run(run_name="logistic_final_evaluation") as eval_run:
    eval_run_id = eval_run.info.run_id

    mlflow.log_param("source_train_run_id", train_run_id)
    mlflow.log_param("source_threshold_run_id", threshold_run_id)
    mlflow.log_param("selected_threshold", selected_threshold)

    test_prob = final_model.predict_proba(X_test)[:, 1]
    test_pred = (test_prob >= selected_threshold).astype(int)

    test_accuracy = accuracy_score(y_test, test_pred)
    test_precision = precision_score(y_test, test_pred, zero_division=0)
    test_recall = recall_score(y_test, test_pred, zero_division=0)
    test_f1 = f1_score(y_test, test_pred, zero_division=0)
    test_auc = roc_auc_score(y_test, test_prob)

    mlflow.log_metric("test_accuracy", test_accuracy)
    mlflow.log_metric("test_precision", test_precision)
    mlflow.log_metric("test_recall", test_recall)
    mlflow.log_metric("test_f1", test_f1)
    mlflow.log_metric("test_auc", test_auc)

    mlflow.sklearn.log_model(final_model, artifact_path="final_model")

    print("\n=== FINAL TEST RESULTS ===")
    print(f"Threshold : {selected_threshold:.2f}")
    print(f"Accuracy  : {test_accuracy:.6f}")
    print(f"Precision : {test_precision:.6f}")
    print(f"Recall    : {test_recall:.6f}")
    print(f"F1-score  : {test_f1:.6f}")
    print(f"ROC-AUC   : {test_auc:.6f}")

    print("\n=== CONFUSION MATRIX ===")
    print(confusion_matrix(y_test, test_pred))

    print("\n=== CLASSIFICATION REPORT ===")
    print(classification_report(y_test, test_pred, digits=6))
```

---

## Cell 10 — Summary cuối cùng

```python
results_summary = {
    "train_run_id": train_run_id,
    "threshold_run_id": threshold_run_id,
    "eval_run_id": eval_run_id,
    "best_params": grid.best_params_,
    "best_cv_f1": grid.best_score_,
    "selected_threshold": selected_threshold,
    "test_accuracy": test_accuracy,
    "test_precision": test_precision,
    "test_recall": test_recall,
    "test_f1": test_f1,
    "test_auc": test_auc
}

print("\n=== SUMMARY ===")
print(results_summary)
```

---

## Logic flow của notebook này

Flow của bạn giờ sẽ là:

**Cell 1–3**
Chuẩn bị import, split data, tạo CV, set MLflow experiment.

**Cell 4**
Train + tuning hyperparameter bằng `GridSearchCV`.
Kết quả:

* có `best_model`
* có `best_params`
* log vào MLflow run số 1

**Cell 6–7**
Dùng `best_model` để tạo **OOF probability** trên `X_train`, sau đó scan threshold.
Kết quả:

* có `selected_threshold`
* log vào MLflow run số 2

**Cell 8–9**
Fit lại model cuối cùng trên toàn bộ `X_train`, rồi evaluate trên `X_test`.
Kết quả:

* có metrics cuối cùng
* log vào MLflow run số 3

---

## Vì sao tôi tách thành 3 run MLflow?

Vì nó rất sạch:

**Run 1 — training**

* lo chuyện chọn hyperparameter tốt nhất

**Run 2 — threshold tuning**

* lo chuyện chọn threshold tốt nhất

**Run 3 — final evaluation**

* lo chuyện đánh giá cuối cùng trên test set

Nhìn trên MLflow UI sẽ rất dễ hiểu hơn kiểu nhét tất cả vào 1 run.

---

## Một lưu ý quan trọng

Trong code gốc bạn gửi, `grid.best_estimator_` thực ra đã được `refit=True` nên nó **đã fit lại trên toàn bộ `X_train` rồi** .
Nghĩa là về mặt kỹ thuật, Cell 8 fit lại lần nữa không sai, nhưng hơi dư.

Nếu bạn muốn gọn hơn, Cell 8 có thể đổi thành:

```python
final_model = grid.best_estimator_
```

Nhưng tôi vẫn để `fit` lại riêng vì:

* dễ đọc flow hơn
* rõ ràng “đây là final model”
* notebook nhìn mạch lạc hơn

---

## Nếu bạn muốn log luôn threshold_df thành artifact CSV

Bạn có thể thêm vào **Cell 6** đoạn này:

```python
threshold_df.to_csv("threshold_tuning_results.csv", index=False)
mlflow.log_artifact("threshold_tuning_results.csv")
```

Vậy trong MLflow bạn sẽ mở được luôn bảng threshold scan.

---

## Nếu bạn muốn log confusion matrix thành file ảnh

Có thể thêm ở Cell 9. Ví dụ:

```python
import matplotlib.pyplot as plt
from sklearn.metrics import ConfusionMatrixDisplay

cm = confusion_matrix(y_test, test_pred)
disp = ConfusionMatrixDisplay(confusion_matrix=cm)
disp.plot()
plt.savefig("confusion_matrix.png", bbox_inches="tight")
mlflow.log_artifact("confusion_matrix.png")
plt.show()
```

---

## Gợi ý tên experiment

Bạn có thể dùng 1 trong 2 cách:

**Cách 1: gom chung**

```python
mlflow.set_experiment("home_credit_logistic_pipeline")
```

**Cách 2: tách rõ hơn**

* `home_credit_logistic_train`
* `home_credit_logistic_threshold`
* `home_credit_logistic_eval`

Nhưng tôi nghĩ cách 1 dễ quản lý hơn, vì 3 run vẫn nằm chung một experiment.

---

Nếu muốn, tôi có thể viết tiếp cho bạn một bản **sạch hơn kiểu production notebook**, có thêm:

* log `classification_report` ra file txt
* log `cv_results_df` ra csv
* register luôn model tốt nhất vào MLflow Model Registry.
