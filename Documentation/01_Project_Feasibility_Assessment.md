# Project 1: Retail Product & Price Intelligence

## 1. Project Overview

Develop a data-driven retail price intelligence solution using publicly available product and price observation datasets.

## 2. Business Objective

Analyze product prices across brands, categories, stores, geographical locations and time to identify pricing patterns, competitive differences and potential business opportunities.

## 3. Data Sources

1. Open Food Facts – Product Master Data.
2. Open Prices – Historical Price Observations.

## 4. Proposed Technology Stack

- Python – Data Extraction and Transformation
- Pandas – Data Cleaning
- MySQL – Database Management
- SQL – Business Analysis
- Excel – Data Validation
- Power BI – Interactive Dashboard
- GitHub – Version Control and Documentation

## 5. Initial Project Scope

Global food product price intelligence with additional exploration of Indian market coverage.

## 6. Initial Business Questions

1. Which brands have the highest average product prices?
2. Which categories demonstrate the greatest price variation?
3. How do prices differ across geographical locations?
4. Which products are relatively expensive compared with competitors?
5. How have observed prices changed over time?
6. Which brands offer better value within comparable categories?
7. What geographical pricing patterns can be identified?

## 7. Known Data Limitations

- Incomplete product information.
- Uneven geographical coverage.
- Missing or inconsistent price records.
- Different currencies.
- Discounted and non-discounted prices.
- Crowdsourced data quality.
- Historical observation dates may differ from upload dates.

## 8. Data Refresh Strategy

Open Prices public exports are regenerated daily. Actual price observation freshness depends on contributor activity.

Our ETL process will record extraction timestamps and source observation dates separately.

## 9. Feasibility Status

Initial feasibility: Promising, subject to detailed dataset profiling, geographical coverage assessment and data quality validation.

## 10. Next Milestone

Download and inspect the source datasets, measure their actual size and assess field completeness before finalizing database design.