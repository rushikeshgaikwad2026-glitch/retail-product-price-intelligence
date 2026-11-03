
# ============================================================
# PROJECT 01: RETAIL PRODUCT & PRICE INTELLIGENCE
# SCRIPT: 03_data_cleaning.py
#
# PURPOSE:
# To build a reusable data cleaning and transformation pipeline.
#
# INPUT:
# data/raw/prices.parquet
#
# OUTPUT:
# data/processed/
# ============================================================


# ------------------------------------------------------------
# 1. IMPORT REQUIRED LIBRARIES
# ------------------------------------------------------------

import pandas as pd
from pathlib import Path


# ------------------------------------------------------------
# 2. DEFINE PROJECT PATHS
# ------------------------------------------------------------

# Locate the main project directory.
project_path = Path(__file__).resolve().parent.parent

# Define the raw dataset location.
raw_file_path = project_path / "data" / "raw" / "prices.parquet"

# Define the processed data folder.
processed_folder = project_path / "data" / "processed"

# Create the processed folder if it does not exist.
processed_folder.mkdir(parents=True, exist_ok=True)


# ------------------------------------------------------------
# 3. LOAD THE RAW DATASET
# ------------------------------------------------------------

print("\nLoading raw dataset...")

# Check whether the source file exists before reading it.
if not raw_file_path.exists():
    raise FileNotFoundError("Raw dataset not found. Please check the file path.")

# Load the original dataset.
df_raw = pd.read_parquet(raw_file_path)

print("Raw dataset loaded successfully!")


# ------------------------------------------------------------
# 4. CREATE A WORKING COPY
# ------------------------------------------------------------

# Never directly modify the original raw dataset.
# A separate copy allows us to clean the data safely.

df_clean = df_raw.copy()

print("\nWorking copy created successfully!")


# ------------------------------------------------------------
# 5. INITIAL DATA VALIDATION
# ------------------------------------------------------------

# Define the important columns required by our project.
required_columns = [
    "id",
    "type",
    "price",
    "currency",
    "date",
    "price_is_discounted"
]

# Check whether all required columns exist.
for column in required_columns:

    if column not in df_clean.columns:
        raise ValueError(f"Required column is missing: {column}")


# Calculate initial dataset statistics.
total_records = len(df_clean)

duplicate_ids = df_clean["id"].duplicated().sum()

missing_ids = df_clean["id"].isna().sum()


# ------------------------------------------------------------
# 6. STANDARDISE DATE FORMAT
# ------------------------------------------------------------

# Convert observation dates into a consistent datetime format.
# Invalid or missing dates will become NaT.
# We retain those records instead of deleting them.

df_clean["date"] = pd.to_datetime(
    df_clean["date"],
    errors="coerce",
    utc=True
)


# ------------------------------------------------------------
# 7. DISPLAY INITIAL VALIDATION RESULTS
# ------------------------------------------------------------

print("\n" + "=" * 50)
print("INITIAL DATA VALIDATION")
print("=" * 50)

print(f"Total records       : {total_records:,}")
print(f"Duplicate IDs       : {duplicate_ids:,}")
print(f"Missing IDs         : {missing_ids:,}")
print(f"Missing dates       : {df_clean['date'].isna().sum():,}")

print("\nAvailable record types:")
print(df_clean["type"].value_counts(dropna=False))

print("\nInitial validation completed.")




# ------------------------------------------------------------
# 8. ZERO PRICE IDENTIFICATION
# ------------------------------------------------------------

# Create a flag to identify zero-price observations.
# We retain these records for investigation.

df_clean["zero_price_flag"] = df_clean["price"] == 0

print("\nZero-price observations:",
      df_clean["zero_price_flag"].sum())


# ------------------------------------------------------------
# 9. STANDARDISE DISCOUNT TYPES
# ------------------------------------------------------------

# For non-discounted observations, discount type is not applicable.
df_clean.loc[
    df_clean["price_is_discounted"] == False,
    "discount_type"
] = "Not Applicable"

# For discounted observations, identify missing or blank types.
discounted_mask = df_clean["price_is_discounted"] == True

df_clean.loc[discounted_mask, "discount_type"] = (
    df_clean.loc[discounted_mask, "discount_type"]
    .fillna("Unknown")
    .replace(r"^\s*$", "Unknown", regex=True)
)

print("\nDiscount type distribution:")
print(df_clean["discount_type"].value_counts())

# ------------------------------------------------------------
# 10. CALCULATE DISCOUNT PERCENTAGE
# ------------------------------------------------------------

# Create a separate column to store discount percentages.
df_clean["discount_percentage"] = pd.NA

# A discount percentage can only be calculated when:
# 1. The observation is marked as discounted.
# 2. Current price is available.
# 3. Original price is available.
# 4. Original price is greater than zero.
# 5. Original price is greater than current price.

valid_discount = (
    (df_clean["price_is_discounted"] == True)
    & (df_clean["price"].notna())
    & (df_clean["price_without_discount"].notna())
    & (df_clean["price_without_discount"] > 0)
    & (df_clean["price_without_discount"] > df_clean["price"])
)

# Calculate the discount percentage only for valid records.
df_clean.loc[valid_discount, "discount_percentage"] = (
    (
        df_clean.loc[valid_discount, "price_without_discount"]
        - df_clean.loc[valid_discount, "price"]
    )
    / df_clean.loc[valid_discount, "price_without_discount"]
) * 100

print("\nValid discount percentage calculations:",
      valid_discount.sum())


# ------------------------------------------------------------
# 11. MISSING DATE IDENTIFICATION
# ------------------------------------------------------------

# Create a flag for observations with missing dates.
# These records will be retained but excluded from time analysis.

df_clean["missing_date_flag"] = df_clean["date"].isna()

print("\nRecords with missing dates:",
      df_clean["missing_date_flag"].sum())


# ------------------------------------------------------------
# 12. DISPLAY CLEANING SUMMARY
# ------------------------------------------------------------

print("\n" + "=" * 50)
print("FIRST CLEANING TRANSFORMATIONS COMPLETED")
print("=" * 50)

print("Total records:", len(df_clean))

print("Zero-price records:",
      df_clean["zero_price_flag"].sum())

print("Missing discount types:",
      (df_clean["discount_type"] == "Unknown").sum())

print("Valid discount calculations:",
      valid_discount.sum())

print("Missing-date records:",
      df_clean["missing_date_flag"].sum())




# ------------------------------------------------------------
# 13. SEPARATE PRODUCT AND CATEGORY OBSERVATIONS
# ------------------------------------------------------------

# PRODUCT and CATEGORY observations have different structures.
# We create separate DataFrames for independent analysis.

df_product = df_clean[
    df_clean["type"] == "PRODUCT"
].copy()

df_category = df_clean[
    df_clean["type"] == "CATEGORY"
].copy()

print("\nObservation separation completed.")

print("PRODUCT records:", len(df_product))
print("CATEGORY records:", len(df_category))


# ------------------------------------------------------------
# 14. VALIDATE SEPARATED DATASETS
# ------------------------------------------------------------

# Check whether the separated record counts match the
# original working dataset.

separated_records = len(df_product) + len(df_category)

print("\nTotal records before separation:", len(df_clean))
print("Total records after separation :", separated_records)

# Identify any records with unexpected observation types.
unexpected_types = df_clean[
    ~df_clean["type"].isin(["PRODUCT", "CATEGORY"])
]

print("Unexpected record types:", len(unexpected_types))

# Confirm that no records have been lost during separation.
if separated_records == len(df_clean) and len(unexpected_types) == 0:
    print("\nDataset separation validation successful!")

else:
    print("\nWARNING: Please investigate the record distribution.")


# ------------------------------------------------------------
# 15. SAVE PROCESSED DATASETS
# ------------------------------------------------------------

# Save the complete cleaned dataset.
# This preserves all observation types in one file.

cleaned_file_path = (
    processed_folder / "prices_cleaned.parquet"
)

df_clean.to_parquet(
    cleaned_file_path,
    index=False,
    compression="snappy"
)


# Save PRODUCT observations separately.

product_file_path = (
    processed_folder / "product_observations.parquet"
)

df_product.to_parquet(
    product_file_path,
    index=False,
    compression="snappy"
)


# Save CATEGORY observations separately.

category_file_path = (
    processed_folder / "category_observations.parquet"
)

df_category.to_parquet(
    category_file_path,
    index=False,
    compression="snappy"
)


# ------------------------------------------------------------
# 16. FINAL DATASET SUMMARY
# ------------------------------------------------------------

print("\n" + "=" * 55)
print("DATA CLEANING PIPELINE COMPLETED")
print("=" * 55)

print(f"Original records : {len(df_raw):,}")
print(f"Cleaned records  : {len(df_clean):,}")
print(f"PRODUCT records  : {len(df_product):,}")
print(f"CATEGORY records : {len(df_category):,}")

print("\nProcessed files saved successfully:")

print(cleaned_file_path)
print(product_file_path)
print(category_file_path)

print("\nAll processing steps completed.")




# ------------------------------------------------------------
# 17. VERIFY SAVED PROCESSED DATASETS
# ------------------------------------------------------------

# Read the saved Parquet files again.
# This verifies that the output files are readable.

df_verified = pd.read_parquet(cleaned_file_path)

df_product_verified = pd.read_parquet(product_file_path)

df_category_verified = pd.read_parquet(category_file_path)


# Check the record counts after reloading.

print("\n" + "=" * 55)
print("SAVED DATASET VERIFICATION")
print("=" * 55)

print("Combined dataset:", len(df_verified))
print("PRODUCT dataset :", len(df_product_verified))
print("CATEGORY dataset:", len(df_category_verified))


# Verify whether the saved dataset counts are correct.

if (
    len(df_verified) == len(df_raw)
    and len(df_product_verified) == len(df_product)
    and len(df_category_verified) == len(df_category)
):
    print("\nAll saved datasets verified successfully!")

else:
    print("\nDataset verification failed. Please investigate.")


# Check whether important transformation columns exist.

expected_columns = [
    "zero_price_flag",
    "discount_percentage",
    "missing_date_flag"
]

for column in expected_columns:

    if column in df_verified.columns:
        print(f"{column}: Available")
    else:
        print(f"{column}: Missing")
