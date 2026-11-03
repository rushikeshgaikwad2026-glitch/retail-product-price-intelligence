
import pandas as pd
import numpy as np
import mysql.connector

import json
import getpass

from pathlib import Path
from datetime import datetime, timezone
from itertools import islice


# ==========================================================
# 1. PROJECT CONFIGURATION
# ==========================================================

project_path = Path(__file__).resolve().parent.parent

processed_file = (
    project_path / "data" / "processed" / "prices_cleaned.parquet"
)

database_name = "retail_price_intelligence"
table_name = "stg_open_prices"

batch_size = 1000

# Unique identifier for this ETL execution
etl_batch_id = datetime.now(timezone.utc).strftime(
    "baseline_%Y%m%d_%H%M%S"
)


# ==========================================================
# 2. LOAD CLEANED DATASET
# ==========================================================

print("\nLoading cleaned Parquet dataset...")

df = pd.read_parquet(processed_file)

print("Dataset loaded successfully.")
print("Total records:", len(df))
print("Total columns:", len(df.columns))


# ==========================================================
# 3. VALIDATE DATASET
# ==========================================================

required_columns = [
    "id",
    "zero_price_flag",
    "discount_percentage",
    "missing_date_flag"
]

missing_columns = [
    column for column in required_columns
    if column not in df.columns
]

if missing_columns:
    raise ValueError(
        f"Required columns missing: {missing_columns}"
    )

if df["id"].isna().any():
    raise ValueError("Observation IDs contain missing values.")

if df["id"].duplicated().any():
    raise ValueError("Duplicate observation IDs found.")

# The cleaned dataset should contain 48 original
# source columns and 3 derived cleaning columns.
if len(df.columns) != 51:
    raise ValueError(
        f"Expected 51 columns, found {len(df.columns)}."
    )

print("Dataset validation successful.")


# ==========================================================
# 4. PREPARE MYSQL INSERT STATEMENT
# ==========================================================

# Add ETL metadata to the original dataset columns.
insert_columns = list(df.columns) + ["etl_batch_id"]

# Backticks protect column names such as:
# type, date, owner and source.
column_names = ", ".join(
    f"`{column}`" for column in insert_columns
)

placeholders = ", ".join(
    ["%s"] * len(insert_columns)
)

insert_query = f"""
    INSERT INTO {table_name}
    ({column_names})
    VALUES ({placeholders})
"""


# ==========================================================
# 5. CONVERT PYTHON VALUES FOR MYSQL
# ==========================================================

def convert_value(value):

    # Missing Python value
    if value is None:
        return None

    # Convert arrays, lists and dictionaries into JSON.
    # This preserves the original tag information.
    if isinstance(value, np.ndarray):
        value = value.tolist()

    if isinstance(value, (list, tuple, dict)):
        return json.dumps(
            value,
            ensure_ascii=False,
            default=str
        )

    # Handle Pandas missing values
    if pd.isna(value):
        return None

    # Convert Pandas timestamps to Python datetime.
    if isinstance(value, pd.Timestamp):

        if value.tzinfo is not None:
            value = value.tz_convert("UTC").tz_localize(None)

        return value.to_pydatetime()

    # Convert NumPy scalar types into Python types.
    if isinstance(value, np.generic):
        value = value.item()

    # MySQL DATETIME does not store timezone information.
    if isinstance(value, datetime):

        if value.tzinfo is not None:
            value = value.astimezone(
                timezone.utc
            ).replace(tzinfo=None)

        return value

    return value


# ==========================================================
# 6. CONNECT TO MYSQL
# ==========================================================

print("\nEnter your MySQL connection details.")

mysql_user = input(
    "MySQL username (usually root): "
).strip().strip('"').strip("'")

mysql_password = getpass.getpass(
    "MySQL password: "
)

connection = mysql.connector.connect(
    host="localhost",
    port=3306,
    user=mysql_user,
    password=mysql_password,
    database=database_name
)

cursor = connection.cursor()

print("\nMySQL connection successful!")


# ==========================================================
# 7. CHECK STAGING TABLE BEFORE INSERTION
# ==========================================================

cursor.execute(
    f"SELECT COUNT(*) FROM {table_name}"
)

existing_records = cursor.fetchone()[0]

if existing_records > 0:

    cursor.close()
    connection.close()

    raise RuntimeError(
        f"Staging table already contains {existing_records} records. "
        "Loading stopped to prevent duplicate insertion."
    )

print("Staging table is empty. Ready for insertion.")


# ==========================================================
# 8. BATCH INSERTION
# ==========================================================

print("\nStarting data insertion...")

total_inserted = 0

try:

# The previous SELECT query already started a transaction.
# We continue using that transaction for the complete data load.

# Iterate through the dataset without creating
# a second full-size copy in memory.
    rows = df.itertuples(index=False, name=None)

    while True:

        current_batch = list(
            islice(rows, batch_size)
        )

        if not current_batch:
            break

        # Convert each row into MySQL-compatible values.
        mysql_rows = []

        for row in current_batch:

            converted_row = tuple(
                convert_value(value)
                for value in row
            )

            # Add ETL batch identifier.
            converted_row = (
                converted_row + (etl_batch_id,)
            )

            mysql_rows.append(converted_row)

        # Insert the current batch.
        cursor.executemany(
            insert_query,
            mysql_rows
        )

        total_inserted += len(mysql_rows)

        print(
            f"Inserted {total_inserted:,} / {len(df):,} records"
        )

    # Commit only after all batches succeed.
    connection.commit()

    print("\nData insertion completed successfully!")

except Exception as error:

    # Roll back the entire transaction if insertion fails.
    connection.rollback()

    print("\nERROR: Data insertion failed.")
    print(error)

    raise

finally:

    cursor.close()
    connection.close()


# ==========================================================
# 9. FINAL INSERTION SUMMARY
# ==========================================================

print("\n" + "=" * 60)
print("ETL EXECUTION SUMMARY")
print("=" * 60)

print("Source records       :", f"{len(df):,}")
print("Records inserted     :", f"{total_inserted:,}")
print("Batch size           :", f"{batch_size:,}")
print("ETL Batch ID         :", etl_batch_id)
print("Target table         :", table_name)

if total_inserted == len(df):
    print("\nSTATUS: SUCCESS")
else:
    print("\nSTATUS: RECORD COUNT MISMATCH")
