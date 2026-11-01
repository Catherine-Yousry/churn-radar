# Customer Churn Prediction -- ML Pipeline

## Project Overview

This project builds a machine learning pipeline to predict customer
churn using the Telco Customer Churn dataset. It covers data
preparation, model training and comparison, threshold selection,
evaluation, and saving the final model for integration with a Streamlit
application.

## Project Files

  -----------------------------------------------------------------------------------------------------
  File                                                              Description
  ----------------------------------------------------------------- -----------------------------------
  `Telco_Customer_Churn_Preprocessed.csv`                           Prepared dataset used for analysis
                                                                    and as the common cleaned-data
                                                                    source.

  `Customer_Churn_ML_Preprocessing.ipynb`                           Main notebook containing data
                                                                    checks, preprocessing, model
                                                                    training, evaluation,
                                                                    feature-importance analysis, and
                                                                    model export.

  `churn_model.pkl`                                                 Serialized final trained model,
                                                                    ready to be loaded by the
                                                                    application.

  `churn_model_metadata.json`                                       Model information, including the
                                                                    selected model and prediction
                                                                    threshold.
  -----------------------------------------------------------------------------------------------------

> If the actual filenames in your shared folder differ, update the names
> in this table to match them.

## Workflow

1.  **Data preparation:** Load the dataset, inspect data quality,
    convert `TotalCharges` to a numeric column, and prepare the target
    variable.
2.  **Data splitting:** Keep 20% as an untouched test set. Split the
    remaining data into training, validation, and feature-importance
    holdout sets.
3.  **Preprocessing:** Apply missing-value imputation, categorical
    encoding, and numerical scaling within the ML pipeline to avoid data
    leakage.
4.  **Model development:** Train and compare Logistic Regression, Random
    Forest, Extra Trees, and XGBoost. Hyperparameter tuning for the
    tree-based models uses Recall.
5.  **Model selection:** Select the final candidate using validation
    F1-score, with Recall and Precision considered in the comparison.
6.  **Threshold selection:** Select a classification threshold using the
    validation set.
7.  **Final evaluation:** Evaluate the selected model once on the
    untouched test set.
8.  **Export:** Save the trained model as a `.pkl` file and its
    supporting metadata as a `.json` file.

## Final Model

-   **Selected model:** Logistic Regression
-   **Selected threshold:** `0.46`
-   **Validation selection metric:** F1-score
-   **Hyperparameter tuning metric for tree-based candidates:** Recall

### Test Set Performance

  Metric        Result
  ----------- --------
  Accuracy       72.2%
  Precision      48.7%
  Recall         82.4%
  F1-score       61.2%
  ROC-AUC        84.1%
  PR-AUC         63.3%

At the selected threshold, the model identifies a substantial proportion
of customers who churn, while some customers predicted to churn do not
actually churn. The threshold represents a trade-off between Recall and
Precision.

## Important Notes

-   The test set is kept separate from model training, model selection,
    and threshold selection.
-   The 11 missing values in `TotalCharges` are intentionally retained
    for further investigation during EDA. The notebook's preprocessing
    pipeline handles missing values during model fitting.
-   Feature importance indicates how much the fitted model relies on
    each feature in the chosen evaluation setup. It does **not**
    establish causation.
-   The saved model and metadata should come from the same completed
    notebook run.
-   When integrating the model into Streamlit, use the same input
    feature names and apply the threshold stored in the metadata.

## How to Use the Saved Model

Load the model in Python:

``` python
import joblib

model = joblib.load("churn_model.pkl")
```

For prediction, provide customer records using the same feature columns
and compatible data types used during training. The model returns churn
probabilities; classify a customer as churn when the probability is
greater than or equal to the selected threshold (`0.46`).

``` python
probabilities = model.predict_proba(customer_data)[:, 1]
predictions = (probabilities >= 0.46).astype(int)
```

## Reproducibility

The notebook uses a fixed random state for reproducible data splitting
and model experiments. For a fresh, consistent run, restart the notebook
kernel and run all cells from top to bottom before exporting the model
and metadata.
