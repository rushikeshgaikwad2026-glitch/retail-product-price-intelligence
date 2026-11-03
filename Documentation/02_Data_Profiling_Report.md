# Project 01: Retail Product & Price Intelligence
## Data Profiling and Quality Assessment

### 1. Source Dataset
- Source: Open Prices
- File: prices.parquet
- Format: Parquet
- Total observations: 338,101
- Total columns: 48
- Observation period: 09-Apr-2009 to 30-Oct-2026

### 2. Record Distribution
- PRODUCT records: 327,550
- CATEGORY records: 10,551
- Unique observation IDs: 338,101
- Duplicate observation IDs: 0

PRODUCT and CATEGORY records will be
maintained as separate analytical types.

### 3. Geographical Coverage
- France: 217,070 observations
- United States: 44,563
- Norway: 24,963
- Germany: 17,557
- India: 485

India will be treated as an exploratory market.
The primary project scope will be global.

### 4. Product Coverage
- Unique product codes: 147,818
- Unique product names: 165,209
- Unique category tags: 640

CATEGORY records contain category tags.
PRODUCT records contain product codes.
These fields must not be treated as missing
in the same way across both record types.

### 5. Price Quality
- Zero prices: 13
- Negative prices: 0
- Missing currencies: 170
- Missing observation dates: 185

Prices will be analysed within comparable
currencies and observation types.

### 6. Discount Quality
- Discounted observations: 33,943
- Original prices available: 30,531
- Original prices missing: 3,412
- Discount types missing: 7,480
- Blank discount types: 43

Discount percentages will only be calculated
when both prices are valid and the original
price is greater than zero.

### 7. Unit Pricing
- KILOGRAM: 7,731
- UNIT: 2,820

Unit-based and kilogram-based observations
will be analysed separately.

### 8. Initial Transformation Decisions
1. Preserve the original raw dataset.
2. Validate observation IDs.
3. Standardise date and numeric fields.
4. Flag zero prices.
5. Preserve records with missing product names.
6. Standardise missing discount types.
7. Separate PRODUCT and CATEGORY records.
8. Avoid direct comparisons across currencies.
9. Flag extreme values for investigation.
10. Maintain source and extraction metadata.

### 9. Project Scope
Global retail price intelligence with
exploratory analysis of the Indian market.

Primary analytical areas:
- Product price comparisons
- Category price comparisons
- Geographical price variation
- Discount analysis
- Historical price observations
- Unit price analysis

### 10. Profiling Status
Initial source-data profiling completed.
Cleaning and transformation pipeline pending.