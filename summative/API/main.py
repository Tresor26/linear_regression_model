import os
import io
import numpy as np
import pandas as pd
import joblib
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.model_selection import train_test_split

# Paths
BASE_DIR  = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(BASE_DIR, "..", "linear_regression")

MODEL_PATH    = os.path.join(MODEL_DIR, "best_yield_model.pkl")
SCALER_PATH   = os.path.join(MODEL_DIR, "scaler.pkl")
LE_AREA_PATH  = os.path.join(MODEL_DIR, "le_area.pkl")
LE_ITEM_PATH  = os.path.join(MODEL_DIR, "le_item.pkl")
DATASET_PATH  = os.path.join(MODEL_DIR, "yield_df.csv")

# Load artifacts at startup
model    = joblib.load(MODEL_PATH)
scaler   = joblib.load(SCALER_PATH)
le_area  = joblib.load(LE_AREA_PATH)
le_item  = joblib.load(LE_ITEM_PATH)

# App
app = FastAPI(
    title="Crop Yield Prediction API",
    description=(
        "Predicts crop yield (hg/ha) from country, crop type, year, "
        "rainfall, pesticide usage, and average temperature. "
        "Built for Rwanda agricultural AI mission."
    ),
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://linear-regression-model-eeak.onrender.com",
        "http://localhost",
        "http://localhost:8000",
        "http://localhost:3000",
        "http://10.0.2.2:8000",
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization"],
)

# Schemas
class PredictionInput(BaseModel):
    area: str = Field(
        ...,
        description="Country name (e.g. 'Rwanda', 'Kenya')",
        example="Rwanda"
    )
    item: str = Field(
        ...,
        description="Crop type (e.g. 'Maize', 'Potatoes')",
        example="Maize"
    )
    year: int = Field(
        ...,
        ge=1990,
        le=2050,
        description="Year between 1990 and 2050",
        example=2013
    )
    average_rainfall_mm_per_year: float = Field(
        ...,
        ge=0.0,
        le=5000.0,
        description="Average annual rainfall in mm (0 – 5000)",
        example=1200.0
    )
    pesticides_tonnes: float = Field(
        ...,
        ge=0.0,
        le=1_000_000.0,
        description="Pesticides used in tonnes (0 – 1,000,000)",
        example=50.0
    )
    avg_temp: float = Field(
        ...,
        ge=-10.0,
        le=50.0,
        description="Average temperature in °C (-10 – 50)",
        example=21.0
    )


class PredictionOutput(BaseModel):
    predicted_yield_hg_per_ha: float
    area: str
    item: str
    year: int


class RetrainResponse(BaseModel):
    message: str
    rows_used: int
    r2_score: float


# Endpoints
@app.get("/", tags=["Health"])
def root():
    """Health check — confirms the API is running."""
    return {
        "status": "online",
        "message": "Crop Yield Prediction API is running.",
        "docs": "/docs",
    }


@app.post("/predict", response_model=PredictionOutput, tags=["Prediction"])
def predict(data: PredictionInput):
    """
    Predict crop yield (hg/ha) for the given inputs.

    Returns the predicted yield along with the echoed input identifiers.
    """
    # Validate categorical inputs
    if data.area not in le_area.classes_:
        raise HTTPException(
            status_code=422,
            detail=(
                f"Unknown country '{data.area}'. "
                f"Valid values: {sorted(le_area.classes_.tolist())}"
            ),
        )
    if data.item not in le_item.classes_:
        raise HTTPException(
            status_code=422,
            detail=(
                f"Unknown crop '{data.item}'. "
                f"Valid values: {sorted(le_item.classes_.tolist())}"
            ),
        )

    area_enc  = le_area.transform([data.area])[0]
    item_enc  = le_item.transform([data.item])[0]
    log_pest  = np.log1p(data.pesticides_tonnes)

    features = np.array([[
        data.average_rainfall_mm_per_year,
        log_pest,
        data.avg_temp,
        data.year,
        area_enc,
        item_enc,
    ]])

    features_scaled = scaler.transform(features)
    prediction = model.predict(features_scaled)[0]

    return PredictionOutput(
        predicted_yield_hg_per_ha=round(float(max(0.0, prediction)), 1),
        area=data.area,
        item=data.item,
        year=data.year,
    )


@app.post("/retrain", response_model=RetrainResponse, tags=["Retraining"])
async def retrain(file: UploadFile = File(...)):
    """
    Retrain the model with new data uploaded as a CSV file.

    The CSV must contain these columns:
    `Area`, `Item`, `Year`, `average_rain_fall_mm_per_year`,
    `pesticides_tonnes`, `avg_temp`, `hg/ha_yield`

    The uploaded data is appended to the existing dataset and the
    Random Forest model is retrained and saved.
    """
    global model, scaler, le_area, le_item

    # Read uploaded file
    contents = await file.read()
    try:
        new_df = pd.read_csv(io.BytesIO(contents))
    except Exception:
        raise HTTPException(status_code=400, detail="Could not parse uploaded file as CSV.")

    required_cols = {
        "Area", "Item", "Year",
        "average_rain_fall_mm_per_year", "pesticides_tonnes",
        "avg_temp", "hg/ha_yield",
    }
    missing = required_cols - set(new_df.columns)
    if missing:
        raise HTTPException(
            status_code=422,
            detail=f"CSV is missing required columns: {sorted(missing)}"
        )

    # Load existing dataset and append new data
    try:
        existing_df = pd.read_csv(DATASET_PATH)
        if "Unnamed: 0" in existing_df.columns:
            existing_df.drop("Unnamed: 0", axis=1, inplace=True)
    except FileNotFoundError:
        existing_df = pd.DataFrame(columns=list(required_cols))

    combined_df = pd.concat([existing_df, new_df], ignore_index=True)
    combined_df.drop_duplicates(inplace=True)

    # Feature engineering (same as notebook)
    combined_df["log_pesticides"] = np.log1p(combined_df["pesticides_tonnes"])

    new_le_area = LabelEncoder()
    new_le_item = LabelEncoder()
    combined_df["area_encoded"] = new_le_area.fit_transform(combined_df["Area"])
    combined_df["item_encoded"] = new_le_item.fit_transform(combined_df["Item"])

    feature_cols = [
        "average_rain_fall_mm_per_year", "log_pesticides",
        "avg_temp", "Year", "area_encoded", "item_encoded",
    ]
    X = combined_df[feature_cols].values
    y = combined_df["hg/ha_yield"].values

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    new_scaler = StandardScaler()
    X_train_scaled = new_scaler.fit_transform(X_train)
    X_test_scaled  = new_scaler.transform(X_test)

    new_model = RandomForestRegressor(
        n_estimators=200, max_depth=15,
        min_samples_leaf=5, random_state=42, n_jobs=-1
    )
    new_model.fit(X_train_scaled, y_train)
    r2 = float(new_model.score(X_test_scaled, y_test))

    # Save updated artifacts
    joblib.dump(new_model,   MODEL_PATH)
    joblib.dump(new_scaler,  SCALER_PATH)
    joblib.dump(new_le_area, LE_AREA_PATH)
    joblib.dump(new_le_item, LE_ITEM_PATH)
    combined_df.to_csv(DATASET_PATH, index=False)

    # Reload into memory
    model   = new_model
    scaler  = new_scaler
    le_area = new_le_area
    le_item = new_le_item

    return RetrainResponse(
        message="Model retrained and saved successfully.",
        rows_used=len(combined_df),
        r2_score=round(r2, 4),
    )
