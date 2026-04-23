SELECT * FROM gdpr.customers_orders_anonymized;
use gdpr;

-- PART 2: PURPOSE-LIMITED ANALYTICAL VIEWS
--
-- Each view contains ONLY the columns needed for a specific use case.
-- Fewer quasi-identifiers per view = better k-anonymity = safer data.

-- VIEW 1: Geographic Analysis
-- Purpose: market analysis by region, country-level sales trends
-- Quasi-identifiers: only country + postal_prefix (2 QIs)
-- Excluded: gender, age, customer identity, IP
create view view_geo_analysis as
Select
    country,
    city,
    postal_code_general as region,
    product_category,
    order_value_random as order_value,
    order_date,
    device_type,
    payment_method
From customers_orders_anonymized;

-- VIEW 2: Customer Behavior
-- Purpose: retention analysis, purchase frequency, lifetime value
-- Quasi-identifiers: only customer_hash + segment
-- Excluded: location, demographics, PII
create view view_customer_behavior as
Select
    customer_id_hashed as customer_hash,
    customer_segment,
    count(*) as total_orders,
    round(Avg(order_value_random), 2) as avg_order_value,
    round(SUM(order_value_random), 2) as total_spent,
    Max(order_date) as first_order,
    Min(order_date) as last_order,
    Dtediff(Max(order_date), Min(order_date)) as customer_lifespan_days
From customers_orders_anonymized
group by customer_hash, customer_segment;

-- VIEW 3: Demographic Analysis
-- Purpose: audience profiling, age/gender trends
-- Quasi-identifiers: gender + country + age_range (3 QIs, no postal)
-- Excluded: postal_code, IP, customer identity
create view view_demographic_analysis AS
Select
    gender,
    country,
    age_range,
    product_category,
    count(*) as n_orders,
    round(Avg(order_value_random), 2) as avg_order_value,
    round(Sum(order_value_random), 2) as total_revenue
from customers_orders_anonymized
group by gender, country, age_range, product_category;

-- VIEW 4: Product Performance
-- Purpose: category analysis, pricing, device trends
-- Quasi-identifiers: NONE (only product and order attributes)
-- This is the safest view — no demographic or geographic data at all
create view view_product_performance as
select
    product_category,
    device_type,
    payment_method,
    count(*) as n_orders,
    round(Avg(order_value_random), 2) as avg_order_value,
    round(Min(order_value_random), 2) as min_order_value,
    round(Max(order_value_random), 2) as max_order_value,
    round(Sum(order_value_random), 2) as total_revenue
from customers_orders_anonymized
group by product_category, device_type, payment_method;