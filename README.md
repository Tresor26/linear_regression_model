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
