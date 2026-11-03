
# ============================================================
# PROJECT 01: RETAIL PRODUCT & PRICE INTELLIGENCE
# SCRIPT: 04_inspect_processed_schema.py
#
# PURPOSE:
# Inspect all columns and data types in the processed dataset
# before designing the final MySQL staging table.
# ============================================================


import pandas as pd
import numpy as np
from pathlib import Path

# --------------------------------------------------
# 1. PROJECT PATHS
# --------------------------------------------------

project_path = Path(__file__).resolve().parent.parent

processed_file = (
    project_path / "data" / "processed" / "prices_cleaned.parquet"
)

# --------------------------------------------------
# 2. LOAD PROCESSED DATASET
# --------------------------------------------------

df = pd.read_parquet(processed_file)

# --------------------------------------------------
# 3. SAFE UNIQUE VALUE COUNT
# --------------------------------------------------

def safe_nunique(series):
    """
    Count unique values where possible.

    Array-like values are converted to strings
    temporarily for counting. Original data is unchanged.
    """

    try:
        return series.nunique()
    except TypeError:
        return series.apply(
            lambda value: str(value) if isinstance(value, np.ndarray)
            else value
        ).nunique()

# --------------------------------------------------
# 4. GENERATE SCHEMA REPORT
# --------------------------------------------------

schema_report = pd.DataFrame({
    "Column_Name": df.columns,
    "Data_Type": [
        str(df[column].dtype) for column in df.columns
    ],
    "Missing_Values": [
        df[column].isna().sum() for column in df.columns
    ],
    "Unique_Values": [
        safe_nunique(df[column]) for column in df.columns
    ]
})

# --------------------------------------------------
# 5. DISPLAY RESULTS
# --------------------------------------------------

print("\n" + "=" * 70)
print("PROCESSED DATASET SCHEMA INSPECTION")
print("=" * 70)

print(schema_report.to_string(index=False))

print("\nTotal columns:", len(df.columns))
print("Total records:", len(df))

# --------------------------------------------------
# 6. SAVE SCHEMA REPORT
# --------------------------------------------------

output_path = (
    project_path / "documentation" / "03_MySQL_Schema_Inspection.csv"
)

schema_report.to_csv(output_path, index=False)

print("\nSchema inspection report saved at:")
print(output_path)
