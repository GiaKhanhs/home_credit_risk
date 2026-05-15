from typing import Dict, Any
from pydantic import BaseModel


class PredictionRequest(BaseModel):
    data: Dict[str, Any]


class PredictionResponse(BaseModel):
    default_probability: float
    prediction: int
    threshold: float