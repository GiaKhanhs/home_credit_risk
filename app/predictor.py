import os
import mlflow
import joblib
import pandas as pd


# MLflow server you used before
MLFLOW_TRACKING_URI = os.getenv(
    "MLFLOW_TRACKING_URI",
    "http://host.docker.internal:5002"
)

mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)

# Replace this with your real XGBoost training run ID
MODEL_URI = "runs:/66fe6ae51d374587a8d9fd6b90e6580b/model"

THRESHOLD_PATH = "artifact/xgboost/selected_threshold.txt"

PREPROCESSING_DIR = "artifact/preprocessing"



class CreditRiskPredictor:

    def __init__(self):
        self.model = mlflow.xgboost.load_model(MODEL_URI)
        self.threshold = self._load_threshold()

        self.ohe = joblib.load(f"{PREPROCESSING_DIR}/ohe.pkl")
        self.scaler = joblib.load(f"{PREPROCESSING_DIR}/scaler.pkl")
        self.categorical_cols = joblib.load(f"{PREPROCESSING_DIR}/categorical_cols.pkl")
        self.numerical_cols = joblib.load(f"{PREPROCESSING_DIR}/numerical_cols.pkl")
        self.feature_columns = joblib.load(f"{PREPROCESSING_DIR}/feature_columns.pkl")

    def _load_threshold(self) -> float:
        if not os.path.exists(THRESHOLD_PATH):
            return 0.5

        with open(THRESHOLD_PATH, "r") as f:
            return float(f.read().strip())

    def _preprocess_input(self, input_data: dict) -> pd.DataFrame:
        raw_df = pd.DataFrame([input_data])

        required_cols = self.categorical_cols + self.numerical_cols

        for col in required_cols:
            if col not in raw_df.columns:
                raw_df[col] = None

        X_cat = raw_df[self.categorical_cols].copy()
        X_num = raw_df[self.numerical_cols].copy()

        X_cat = X_cat.fillna("Unknown")
        X_num = X_num.fillna(0)

        X_cat_encoded = self.ohe.transform(X_cat)
        encoded_cat_features = self.ohe.get_feature_names_out(self.categorical_cols)

        X_cat_encoded_df = pd.DataFrame(
            X_cat_encoded,
            columns=encoded_cat_features
        )

        X_num_scaled = self.scaler.transform(X_num)

        X_num_scaled_df = pd.DataFrame(
            X_num_scaled,
            columns=self.numerical_cols
        )

        X_processed = pd.concat(
            [X_num_scaled_df, X_cat_encoded_df],
            axis=1
        )

        X_processed = X_processed.reindex(
            columns=self.feature_columns,
            fill_value=0
        )

        return X_processed

    def predict(self, input_data: dict) -> dict:
        X_processed = self._preprocess_input(input_data)

        probability = float(
            self.model.predict_proba(X_processed)[:, 1][0]
        )

        prediction = int(probability >= self.threshold)

        return {
            "default_probability": probability,
            "prediction": prediction,
            "threshold": self.threshold
        }


predictor = CreditRiskPredictor()