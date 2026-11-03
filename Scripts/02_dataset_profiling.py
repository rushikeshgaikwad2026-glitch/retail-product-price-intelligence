
# ============================================================
# PROJECT 01: RETAIL PRODUCT & PRICE INTELLIGENCE
# SCRIPT: 02_dataset_profiling.py
#
# PURPOSE:
# To inspect the Open Prices dataset and generate a structured
# data profiling report before starting the data cleaning stage.
#
# OUTPUT:
# documentation/02_Data_Profiling_Report.md
#
# TOOLS:
# Python, Pandas, pathlib
# ============================================================


# ------------------------------------------------------------
# 1. IMPORT REQUIRED LIBRARIES
# ------------------------------------------------------------

import pandas as pd
from pathlib import Path


# ------------------------------------------------------------
# 2. DEFINE PROJECT PATHS
# ------------------------------------------------------------

# Find the main project folder using the location of this script.
# This avoids hardcoding the full Windows directory path.

project_path = Path(__file__).resolve().parent.parent

# Define the input dataset path.
raw_file_path = project_path / "data" / "raw" / "prices.parquet"

# Define the output report path.
report_folder = project_path / "documentation"
report_file_path = report_folder / "02_Data_Profiling_Report.md"

# Create the documentation folder if it does not already exist.
report_folder.mkdir(parents=True, exist_ok=True)


# ------------------------------------------------------------
# 3. LOAD THE DATASET
# ------------------------------------------------------------

print("\nLoading Open Prices dataset...")

# Read the Parquet file into a Pandas DataFrame.
df = pd.read_parquet(raw_file_path)

print("Dataset loaded successfully!")


# ------------------------------------------------------------
# 4. BASIC DATASET INFORMATION
# ------------------------------------------------------------

# Calculate the number of rows and columns.
total_rows = df.shape[0]
total_columns = df.shape[1]

# Calculate the number of unique observation IDs.
unique_ids = df["id"].nunique()

# Identify duplicate observation IDs.
duplicate_ids = df["id"].duplicated().sum()

# Calculate the earliest and latest observation dates.
# Convert date values into datetime format for date calculations.
df["date"] = pd.to_datetime(df["date"], errors="coerce", utc=True)

earliest_date = df["date"].min()
latest_date = df["date"].max()

# Count records where the observation date is missing.
missing_dates = df["date"].isna().sum()


# ------------------------------------------------------------
# 5. RECORD TYPE ANALYSIS
# ------------------------------------------------------------

# The dataset contains two observation types:
# PRODUCT and CATEGORY.
# We analyse them separately because their fields differ.

record_type_counts = df["type"].value_counts(dropna=False)

product_records = df[df["type"] == "PRODUCT"]
category_records = df[df["type"] == "CATEGORY"]

total_product_records = len(product_records)
total_category_records = len(category_records)


# ------------------------------------------------------------
# 6. MISSING VALUE ANALYSIS
# ------------------------------------------------------------

# isna() identifies missing values.
# sum() calculates the number of missing values in each column.

missing_values = df.isna().sum()

# Keep only columns that contain at least one missing value.
missing_values = missing_values[missing_values > 0]

# Sort columns by missing-value count, from highest to lowest.
missing_values = missing_values.sort_values(ascending=False)


# ------------------------------------------------------------
# 7. PRODUCT AND CATEGORY COVERAGE
# ------------------------------------------------------------

# Count unique product codes and product names.
unique_product_codes = df["product_code"].nunique()
unique_product_names = df["product_name"].nunique()

# Category tags are populated mainly for CATEGORY records.
unique_categories = df["category_tag"].nunique()

# Count records with missing product names.
missing_product_names = df["product_name"].isna().sum()


# ------------------------------------------------------------
# 8. GEOGRAPHICAL ANALYSIS
# ------------------------------------------------------------

# Count observations by country.
country_distribution = (
    df["location_osm_address_country"]
    .value_counts()
    .head(20)
)

# Count observations from India using the country code.
# Country code is more reliable than searching country names,
# which may have different language or spelling variations.

india_records = df[
    df["location_osm_address_country_code"] == "IN"
]

india_observations = len(india_records)

# Identify the number of unique Indian city labels.
india_unique_cities = (
    india_records["location_osm_address_city"].nunique()
)

# Find the most frequently observed Indian cities.
india_top_cities = (
    india_records["location_osm_address_city"]
    .value_counts()
    .head(15)
)


# ------------------------------------------------------------
# 9. YEAR-WISE OBSERVATION ANALYSIS
# ------------------------------------------------------------

# Extract the year from the observation date.
# Records with missing dates will have a missing year.

df["observation_year"] = df["date"].dt.year

# Count observations for each year.
year_distribution = (
    df["observation_year"]
    .value_counts()
    .sort_index()
)


# ------------------------------------------------------------
# 10. PRICE QUALITY ANALYSIS
# ------------------------------------------------------------

# Convert price values into numeric format for calculations.
# Invalid values, if any, are converted into missing values.

df["price_numeric"] = pd.to_numeric(
    df["price"],
    errors="coerce"
)

# Calculate the number of zero and negative prices.
zero_prices = (df["price_numeric"] == 0).sum()
negative_prices = (df["price_numeric"] < 0).sum()

# Count observations with missing currency.
missing_currency = df["currency"].isna().sum()

# Calculate price statistics separately by currency.
# We do not compare raw prices across different currencies.

price_statistics = (
    df.groupby("currency", dropna=False)["price_numeric"]
    .agg(["count", "mean", "min", "max"])
    .sort_values("count", ascending=False)
    .head(15)
)


# ------------------------------------------------------------
# 11. DISCOUNT ANALYSIS
# ------------------------------------------------------------

# Count discounted and non-discounted observations.
discount_distribution = (
    df["price_is_discounted"]
    .value_counts(dropna=False)
)

discounted_records = df[
    df["price_is_discounted"] == True
]

total_discounted = len(discounted_records)

# Count discounted records that have an original price.
original_price_available = (
    discounted_records["price_without_discount"].notna().sum()
)

# Count discounted records where original price is missing.
original_price_missing = (
    discounted_records["price_without_discount"].isna().sum()
)

# Standardise missing and blank discount types for reporting.
discount_types = (
    discounted_records["discount_type"]
    .fillna("Unknown")
    .replace(r"^\s*$", "Unknown", regex=True)
)

discount_type_distribution = discount_types.value_counts()


# ------------------------------------------------------------
# 12. UNIT PRICING ANALYSIS
# ------------------------------------------------------------

# Unit pricing is analysed separately because price per kilogram
# and price per unit are not directly comparable.

unit_pricing_distribution = (
    df["price_per"]
    .value_counts(dropna=True)
)


# ------------------------------------------------------------
# 13. CREATE THE MARKDOWN REPORT
# ------------------------------------------------------------

# A list is used to build the report line by line.
# At the end, all lines are joined and written to a Markdown file.

report = []

report.append("# Project 01: Retail Product & Price Intelligence")
report.append("## Data Profiling and Quality Assessment")
report.append("")
report.append("### 1. Source Dataset")
report.append("- Source: Open Prices")
report.append("- File: prices.parquet")
report.append("- Format: Parquet")
report.append(f"- Total observations: {total_rows:,}")
report.append(f"- Total columns: {total_columns}")
report.append(f"- Unique observation IDs: {unique_ids:,}")
report.append(f"- Duplicate observation IDs: {duplicate_ids:,}")
report.append(f"- Earliest observation: {earliest_date}")
report.append(f"- Latest observation: {latest_date}")
report.append(f"- Missing observation dates: {missing_dates:,}")
report.append("")

report.append("### 2. Record Distribution")
for record_type, count in record_type_counts.items():
    report.append(f"- {record_type}: {count:,}")

report.append("")
report.append("PRODUCT and CATEGORY records will be maintained as separate analytical types.")
report.append("")

report.append("### 3. Missing Value Analysis")
report.append("| Column | Missing Values |")
report.append("|---|---:|")

for column, count in missing_values.items():
    report.append(f"| {column} | {count:,} |")

report.append("")
report.append("Missing values will be interpreted according to the meaning of each field and record type.")
report.append("")

report.append("### 4. Product Coverage")
report.append(f"- Unique product codes: {unique_product_codes:,}")
report.append(f"- Unique product names: {unique_product_names:,}")
report.append(f"- Unique category tags: {unique_categories:,}")
report.append(f"- Missing product names: {missing_product_names:,}")
report.append("")

report.append("### 5. Geographical Coverage")
report.append("| Country | Observations |")
report.append("|---|---:|")

for country, count in country_distribution.items():
    report.append(f"| {country} | {count:,} |")

report.append("")
report.append(f"- India observations: {india_observations:,}")
report.append(f"- Unique Indian city labels: {india_unique_cities:,}")
report.append("")
report.append("#### Top Indian Cities")
report.append("| City | Observations |")
report.append("|---|---:|")

for city, count in india_top_cities.items():
    report.append(f"| {city} | {count:,} |")

report.append("")
report.append("### 6. Year-wise Observation Distribution")
report.append("| Year | Observations |")
report.append("|---|---:|")

for year, count in year_distribution.items():
    report.append(f"| {int(year)} | {count:,} |")

report.append("")
report.append("Observation volume varies significantly by year. This does not necessarily represent growth in retail sales or market size.")
report.append("")

report.append("### 7. Price Quality")
report.append(f"- Zero-price observations: {zero_prices:,}")
report.append(f"- Negative-price observations: {negative_prices:,}")
report.append(f"- Missing currency values: {missing_currency:,}")
report.append("")
report.append("#### Price Statistics by Currency")
report.append("| Currency | Count | Average Price | Minimum Price | Maximum Price |")
report.append("|---|---:|---:|---:|---:|")

for currency, row in price_statistics.iterrows():
    currency_name = "Unknown" if pd.isna(currency) else currency
    report.append(
        f"| {currency_name} | {int(row['count']):,} "
        f"| {row['mean']:.2f} | {row['min']:.2f} | {row['max']:.2f} |"
    )

report.append("")
report.append("Prices must be analysed within comparable currencies. Direct comparison across currencies is not valid without a documented currency conversion method.")
report.append("")

report.append("### 8. Discount Analysis")
report.append(f"- Total discounted observations: {total_discounted:,}")
report.append(f"- Original prices available: {original_price_available:,}")
report.append(f"- Original prices missing: {original_price_missing:,}")
report.append("")
report.append("#### Discount Type Distribution")
report.append("| Discount Type | Observations |")
report.append("|---|---:|")

for discount_type, count in discount_type_distribution.items():
    report.append(f"| {discount_type} | {count:,} |")

report.append("")
report.append("Discount percentages will only be calculated when valid current and original prices are available and the original price is greater than zero.")
report.append("")

report.append("### 9. Unit Pricing")
report.append("| Unit Type | Observations |")
report.append("|---|---:|")

for unit_type, count in unit_pricing_distribution.items():
    report.append(f"| {unit_type} | {count:,} |")

report.append("")
report.append("Kilogram-based and unit-based observations will be analysed separately.")
report.append("")

report.append("### 10. Initial Transformation Decisions")
report.append("1. Preserve the original raw dataset.")
report.append("2. Validate observation IDs.")
report.append("3. Standardise date and numeric fields.")
report.append("4. Keep PRODUCT and CATEGORY records separate.")
report.append("5. Flag zero prices instead of deleting them automatically.")
report.append("6. Preserve records with missing product names.")
report.append("7. Standardise missing and blank discount types.")
report.append("8. Exclude missing-date records from time-series analysis.")
report.append("9. Avoid direct comparisons across currencies.")
report.append("10. Investigate extreme values within comparable groups.")
report.append("11. Maintain source and extraction metadata.")
report.append("")

report.append("### 11. Project Scope")
report.append("Global retail price intelligence with an exploratory analysis of the Indian market.")
report.append("")
report.append("Primary analytical areas:")
report.append("- Product price comparisons")
report.append("- Category price comparisons")
report.append("- Geographical price variation")
report.append("- Discount analysis")
report.append("- Historical price observations")
report.append("- Unit price analysis")
report.append("")

report.append("### 12. Profiling Status")
report.append("Initial source-data profiling completed.")
report.append("Cleaning and transformation pipeline pending.")
report.append("")

# Join all report lines into one Markdown text.
report_content = "\n".join(report)

# Write the report to the documentation folder.
report_file_path.write_text(
    report_content,
    encoding="utf-8"
)


# ------------------------------------------------------------
# 14. DISPLAY EXECUTION SUMMARY
# ------------------------------------------------------------

print("\n" + "=" * 55)
print("DATA PROFILING COMPLETED SUCCESSFULLY")
print("=" * 55)

print(f"Total rows       : {total_rows:,}")
print(f"Total columns    : {total_columns}")
print(f"Duplicate IDs    : {duplicate_ids:,}")
print(f"Zero prices      : {zero_prices:,}")
print(f"India records    : {india_observations:,}")

print("\nReport generated at:")
print(report_file_path)

print("\nYou can now open the Markdown report in VS Code.")
