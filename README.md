# Crop Yield Prediction

**Mission:** My mission is to transform agriculture in Rwanda by leveraging artificial intelligence and data-driven technologies to improve soil management, increase farm productivity, and empower farmers to make informed decisions. By 2030, I aim to help Rwanda achieve food self-sufficiency and expand agricultural exports, contributing to economic growth, job creation, and sustainable farming.

**Problem:** Rwandan farmers lack access to data-driven tools to predict crop yields based on environmental and agricultural inputs, leading to poor planning and resource misallocation. This project builds a machine learning model that predicts crop yield (hg/ha) from rainfall, temperature, pesticide usage, and location data — enabling precision agriculture decisions.

**Dataset:** [Crop Yield Prediction Dataset](https://www.kaggle.com/datasets/patelris/crop-yield-prediction-dataset) — sourced from the FAO (Food and Agriculture Organization) and World Bank. Contains 28,242 records across 101 countries, 10 crop types, spanning 1990–2013, with features: average rainfall (mm/yr), pesticides (tonnes), average temperature (°C), country, and crop type.

---

## Project Structure

```
linear_regression_model/
├── summative/
│   ├── linear_regression/
│   │   └── multivariate.ipynb
│   └── API/
└── FlutterApp/
```

---

## How to Run the Notebook

### 1. Clone the repository

```bash
git clone https://github.com/Tresor26/linear_regression_model.git
cd linear_regression_model
```

### 2. Create and activate a virtual environment

```bash
python -m venv venv
source venv/bin/activate        # On Windows: venv\Scripts\activate
```

### 3. Install dependencies

```bash
pip install numpy pandas matplotlib seaborn scikit-learn jupyter
```

### 4. Download the dataset

Download the dataset from [Kaggle](https://www.kaggle.com/datasets/patelris/crop-yield-prediction-dataset) and place `yield_df.csv` inside:

```
summative/linear_regression/
```

### 5. Launch Jupyter and open the notebook

```bash
jupyter notebook summative/linear_regression/multivariate.ipynb
```

### 6. Run all cells

In Jupyter, go to **Kernel → Restart & Run All** to execute the full pipeline:
- Data loading & cleaning
- Feature engineering & standardization
- Visualizations
- Model training (Linear Regression, Decision Tree, Random Forest, SGD)
- Loss curve & scatter plots
- Saving the best model (`best_yield_model.pkl`)

### 7. Make a prediction

The final cell in the notebook demonstrates how to load the saved model and predict yield for a single input. The saved model file `best_yield_model.pkl` will appear in `summative/linear_regression/` after running all cells.

---

## Model Performance

Four models were trained and compared. Random Forest was selected for deployment.

| Model | Test R² | Test RMSE |
|---|---|---|
| Linear Regression | 0.0922 | 81,113 hg/ha |
| SGD Regressor | 0.0891 | 81,256 hg/ha |
| Decision Tree | 0.9397 | 20,911 hg/ha |
| **Random Forest** | **0.9738** | **13,777 hg/ha** |

**Random Forest config:** `n_estimators=200, max_depth=15, min_samples_leaf=5`

Linear and SGD models scored ~0.09 because crop yield has a non-linear relationship with the features — a straight line cannot capture that complexity. Decision Tree and Random Forest handle non-linearity effectively, with Random Forest achieving the lowest RMSE.

---

## API

**Live URL:** `https://linear-regression-model-eeak.onrender.com`

**Swagger UI (interactive docs):** `https://linear-regression-model-eeak.onrender.com/docs`

### Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/` | Health check |
| `POST` | `/predict` | Predict crop yield |
| `POST` | `/retrain` | Retrain model with new CSV data |

### `POST /predict`

**Request body:**
```json
{
  "area": "Rwanda",
  "item": "Maize",
  "year": 2013,
  "average_rainfall_mm_per_year": 1200.0,
  "pesticides_tonnes": 50.0,
  "avg_temp": 21.0
}
```

**Field constraints:**

| Field | Type | Range |
|---|---|---|
| `area` | string | One of 101 valid countries |
| `item` | string | One of 10 valid crop types |
| `year` | int | 1990 – 2050 |
| `average_rainfall_mm_per_year` | float | 0 – 5000 mm |
| `pesticides_tonnes` | float | 0 – 1,000,000 |
| `avg_temp` | float | -10 – 50 °C |

**Response:**
```json
{
  "predicted_yield_hg_per_ha": 28505.3,
  "area": "Rwanda",
  "item": "Maize",
  "year": 2013
}
```

### `POST /retrain`

Upload a CSV file with columns: `Area`, `Item`, `Year`, `average_rain_fall_mm_per_year`, `pesticides_tonnes`, `avg_temp`, `hg/ha_yield`.

The API appends the new data to the existing dataset, retrains the Random Forest with the same hyperparameters, and saves all updated artifacts (model, scaler, encoders) in place — no redeployment needed.

**Response:**
```json
{
  "message": "Model retrained and saved successfully.",
  "rows_used": 28500,
  "r2_score": 0.9741
}
```

### CORS Configuration

CORS is set to `allow_origins=["*"]` so the API accepts requests from any origin. This is intentional — the Flutter app runs across Android, iOS, and web from different origins, and the Swagger UI also requires open access.

### Run the API Locally

```bash
# Install dependencies
pip install -r summative/API/requirements.txt

# Start the server
uvicorn summative.API.main:app --reload
```

API available at `http://localhost:8000`. Swagger docs at `http://localhost:8000/docs`.

---

## Flutter Mobile App

### Prerequisites

- Flutter SDK `^3.10.8`
- Android emulator or physical device

### Run the App

```bash
cd summative/FlutterApp/crop_yield_app
flutter pub get
flutter run
```

The app calls the live Render API by default. To use a local API, update the endpoint URL in `lib/screens/prediction_screen.dart`.

### Features

- Select country and crop type from validated dropdowns (101 countries, 10 crops)
- Enter year, rainfall, pesticide usage, and temperature
- Press **Predict** to receive yield in hg/ha and tonnes/ha
- Animated result card with success and error states
- Reset button to clear all inputs

### Dependencies

```yaml
http: ^1.2.2          # HTTP client for API calls
cupertino_icons: ^1.0.8
```

---

## Demo Video

[![Crop Yield Predictor Demo](https://img.youtube.com/vi/Mmeuc8c7DnU/0.jpg)](https://youtu.be/Mmeuc8c7DnU)
