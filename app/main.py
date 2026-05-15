from fastapi import FastAPI
from app.schemas import PredictionRequest, PredictionResponse
from app.predictor import predictor


app = FastAPI(
    title="Home Credit Default Risk API",
    description="API for predicting customer default risk using the selected XGBoost model.",
    version="1.0.0"
)


@app.get("/")
def root():
    return {
        "message": "Home Credit Default Risk API is running."
    }


@app.get("/health")
def health_check():
    return {
        "status": "ok"
    }


@app.post("/predict", response_model=PredictionResponse)
def predict(request: PredictionRequest):
    return predictor.predict(request.data)