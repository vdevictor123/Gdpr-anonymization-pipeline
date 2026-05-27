# Analytical Queries on Anonymized Views

## Purpose

This folder proves that anonymizing data does not reduce its analytical value.
Each file contains queries against one of the four purpose-limited views 
created in the anonymization pipeline.

## Why This Folder Exists

A common concern about GDPR anonymization is that it destroys analytical utility.
These queries demonstrate the opposite: aggregations, rankings, window functions,
CTEs, and trend analysis all work correctly on fully anonymized data.

## Views Covered

| File | View | Use Case |
|------|------|----------|
| queries_customer_behavior.sql | view_customer_behavior | Retention, LTV, recency |
| queries_demographic_analysis.sql | view_demographic_analysis | Audience profiling |
| queries_product_performance.sql | view_product_performance | Category and pricing analysis |
| queries_geo_analysis.sql | view_geo_analysis | Regional trends |

## SQL Techniques Demonstrated

- Window functions: `ROW_NUMBER`, `RANK`, `LAG`, `SUM OVER`, `DENSE_RANK`
- CTEs (`WITH` clauses)
- Conditional aggregation (`CASE WHEN`)
- Date functions: `TIMESTAMPDIFF`, `DATE_FORMAT`
- Multi-step analytical patterns
