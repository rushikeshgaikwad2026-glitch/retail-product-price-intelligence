# Advanced Analytics — Geographic Price Benchmarking and Outlier Investigation

## 1. Geographic Apple Price Benchmarking

The analysis compared apple prices across countries using the Open Prices dataset, restricted to EUR and KILOGRAM observations.

| Country | Observations | Average (EUR/kg) | Median (EUR/kg) |
|---|---:|---:|---:|
| France | 289 | 3.28 | 3.01 |
| Germany | 16 | 2.30 | 2.39 |
| Belgium | 6 | 4.08 | 3.14 |

France had a median observed price of €3.01/kg, compared with €2.39/kg in Germany. Germany's median was approximately 20.6% lower than France's.

Belgium had only six observations, so its results should be treated as exploratory.

These findings describe the available crowdsourced observations, not representative national retail price indices.

## 2. Location-Level Benchmarking

The French location analysis identified Veynes and Avèze as locations with unusually high average observed prices.

| Location | Observations | Average (EUR/kg) | Minimum | Maximum |
|---|---:|---:|---:|---:|
| Veynes | 3 | 12.30 | 3.50 | 29.90 |
| Avèze | 2 | 7.91 | 2.77 | 13.04 |
| Grenoble | 2 in the high-price investigation | — | — | 8.95 |

Small observation counts limit the reliability of location-level averages.

## 3. Statistical Outlier Detection

The French apple-price distribution had:

- Overall average: €3.28/kg
- Standard deviation: €1.90/kg

Z-score analysis identified three unusually high observations:

| Location | Observation ID | Price | Z-score |
|---|---:|---:|---:|
| Veynes | 62870 | €29.90 | 14.00 |
| Avèze | 95330 | €13.04 | 5.13 |
| Grenoble | 91962 | €8.95 | 2.98 |

## 4. Source-Level Investigation

The three observations were examined in the original staging table.

All three used PRICE_TAG evidence. Their proof dates matched their observation dates, and receipt quantities were missing.

The Veynes investigation also identified two observations on 16 December 2024:

- Observation 59876: €3.50/kg, RECEIPT evidence.
- Observation 62870: €29.90/kg, PRICE_TAG evidence.

The difference is substantial, but the available fields do not establish whether these observations represent identical apple varieties or product grades.

## 5. Data Treatment Decision

- Preserve all original observations.
- Do not automatically delete statistical outliers.
- Flag unusually high observations for investigation.
- Retain source and proof metadata for traceability.
- Compare metrics with and without flagged observations when useful.
- Treat statistical anomalies as investigation candidates, not confirmed data errors.

## 6. Analytical Limitations

- The dataset is crowdsourced and is not a representative retail survey.
- Product variety and quality may differ within the same category.
- Observation counts vary considerably by country and location.
- Z-scores can be influenced by skewed price distributions.
- Country-level differences should not be interpreted as definitive national price differences.