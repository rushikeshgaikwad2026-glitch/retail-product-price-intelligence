# Retail Product & Price Intelligence

An end-to-end data analytics project that transforms crowdsourced retail price observations into structured data, analytical insights, and interactive Power BI dashboards.

<img width="604" height="338" alt="image" src="https://github.com/user-attachments/assets/b0da118d-e275-4087-8386-5265a39055dc" />


## 1. Project Overview

Retail prices can vary across products, categories, locations, currencies, and time periods. This project analyses historical retail price observations to understand these patterns and identify areas requiring further investigation.

The project demonstrates an end-to-end analytics workflow using Python, MySQL, SQL, and Power BI.

**Business objective:** Build a structured analytical solution to explore retail price performance, category-level differences, geographic coverage, price trends, discounts, and unusual price observations.

## 2. Business Questions

- Which products and categories have the highest observed prices?
- How do observed prices vary across locations?
- How do average and median prices differ across categories?
- How has observed pricing changed over time?
- Which categories have unusually high price observations?
- How does observation coverage vary by country?
- How frequently are products recorded with discounts?

## 3. Technology Stack

<img width="300" height="304" alt="Screenshot 2026-10-31 145014" src="https://github.com/user-attachments/assets/3d5dc42d-7b84-458c-8701-686aead3e11b" />


| Technology | Purpose |
|---|---|
| Python | Data profiling, cleaning, and ETL |
| Pandas and NumPy | Data processing and analysis |
| MySQL | Relational database and analytical views |
| SQL | Data modelling, transformations, and analysis |
| Power BI | Interactive dashboards and visual analytics |
| Git and GitHub | Version control and project documentation |

## 4. Data Source

**Open Prices – Open Food Facts**

- Website: https://prices.openfoodfacts.org/
- API documentation: https://prices.openfoodfacts.org/api/docs
- Dataset: https://huggingface.co/datasets/openfoodfacts/open-prices

The dataset contains crowdsourced retail price observations, including product details, prices, currencies, dates, locations, and discount information.

The public dataset export is regenerated periodically (daily). Individual observations are crowdsourced records and should not be interpreted as guaranteed current shelf prices.

## 5. Dataset Profile

| Metric | Result |
|---|---:|
| Total source records | 338,101 |
| Product observations | 327,550 |
| Category observations | 10,551 |
| Distinct product codes | 147,818 |
| Product categories | 640 |
| Product currencies | 94 |
| Missing observation dates | 185 |

The dataset includes observations from multiple countries, with France representing the largest geographic share.

## 6. Data Engineering Workflow

1. **Data acquisition:** Downloaded the historical Parquet dataset.
2. **Data profiling:** Examined dimensions, data types, missing values, duplicates, price distributions, currencies, and geographic coverage.
3. **Data cleaning:** Created cleaned product and category observation datasets and added analytical flags.
4. **Database loading:** Loaded the source records into MySQL staging tables.
5. **Data modelling:** Designed dimension and fact tables.
6. **SQL analytics:** Developed analytical queries and reusable Power BI views.
7. **Visualization:** Connected Power BI to MySQL and developed interactive analytical pages.

## 7. Database Architecture

The MySQL database is named `retail_price_intelligence`.

Key dimensions:
- `dim_products`
- `dim_product_names`
- `dim_locations`
- `dim_date`
- `dim_currency`
- `dim_categories`

Key fact tables:
- `fact_price_observations`
- `fact_category_observations`

A staging table, `stg_open_prices`, stores the loaded source records.

## 8. Power BI Dashboard

The Power BI report contains six analytical pages:

1. **Executive Dashboard** – High-level KPIs and a consolidated view of project performance.
2. **Executive Summary** – Key business findings, observations, and actionable insights.
3. **Product Intelligence** – Product-level price performance, observation coverage, and discount patterns.
4. **Category Intelligence** – Category-level price benchmarks, average-versus-median comparisons, and outlier patterns.
5. **Geographic Intelligence** – Country-level price benchmarks, geographic coverage, and price variation.
6. **Price Trends & Anomalies** – Monthly price trends, observation volumes, and high-price outlier analysis.

Power BI file: `Dashboards/Project_01_Retail_Price_Intelligence.pbix`

## 9. Key Analytical Observations

- The dataset has substantially greater observation coverage in France than in other countries.
- Approximately 10.04% of all source records are marked as discounted.
- Approximately 93.6% of observations fall between 2024 and 2026; 2026 is an incomplete year in this dataset.
- Price comparisons require currency and measurement-basis awareness.
- High-price outliers are investigation flags, not automatically data errors.
- Differences in observation coverage and category mix limit direct country-level comparisons.

## 10. Important Limitations

- The dataset is crowdsourced and may contain reporting or measurement inconsistencies.
- Observation counts do not necessarily represent market share or sales volume.
- Prices in different currencies should not be compared without currency conversion.
- Prices recorded using different measurement bases should not be compared directly.
- Geographic comparisons may be affected by differences in sample size and category mix.
- Monthly and annual trends reflect the available observations, not necessarily changes in the wider retail market.
- The source export is periodically regenerated; it does not guarantee real-time retail prices.

## 11. Project Structure

```text
Project_01_Retail_Product_Price_Intelligence/
│
├── Dashboards/
│   └── Project_01_Retail_Price_Intelligence.pbix
│
├── Data/
│   ├── Raw/
│   ├── Processed/
│   └── Final/
│
├── Documentation/
│
├── Notebooks/
│
├── Reports/
│
├── Scripts/
│
├── SQL/
│
├── requirements.txt
├── .gitignore
└── README.md
```

## 12. Future Enhancements

- Automate periodic data extraction through the Open Prices API.
- Implement incremental ETL and data refresh monitoring.
- Enrich product information through available public APIs.
- Add further price benchmarking and anomaly investigation.
- Publish additional analytical documentation and dashboard previews.

## 13. Reproducibility and Data Usage

The Python scripts, SQL scripts, and Power BI report document the project workflow. The raw and processed datasets are maintained locally and are excluded from the Git repository.

Refer to the source provider's licensing terms before redistributing data or derived datasets. Open Prices data is associated with the Open Database License (ODbL); attribution and share-alike obligations may apply.

## Author

**Data Analytics Portfolio Project**

Project 01 – Retail Product & Price Intelligence

**Status:** Analytical development and dashboard implementation completed; repository packaging and future refresh automation are ongoing.
