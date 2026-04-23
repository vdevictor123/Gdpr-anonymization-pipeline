
-- 07_noise_injection_order_value.sql
--
-- Technique: NOISE INJECTION (random perturbation ±5%)
-- Column:    order_value_eur
--
-- WHY:
--   Exact monetary values can be used for re-identification. If an attacker
--   knows "customer X bought something for exactly €44.48 on July 4th",
--   they can search the anonymized dataset for that exact amount + date
--   and find the row. Adding ±5% random noise breaks that exact match
--   while preserving statistical properties (mean, median, distribution).
--
-- HOW:
--   Multiply order_value_eur by a random factor between 0.95 and 1.05.
--   Formula: value * (0.95 + RAND() * 0.10)
--   - RAND() returns a random number between 0 and 1
--   - RAND() * 0.10 gives a number between 0 and 0.10
--   - 0.95 + (0 to 0.10) gives a factor between 0.95 and 1.05
--
-- IMPORTANT:
--   RAND() is uniform distribution, not Gaussian. This is a known limitation.
--   In a production system you would use Gaussian noise (normal distribution)
--   for better statistical properties. MySQL does not have a native Gaussian
--   random function, so uniform ±5% is a reasonable approximation for this
--   demo. This limitation is documented intentionally.
--
-- EXAMPLE:
--   Original : 44.48
--   Noised   : 42.76  (factor 0.9613 → approx -3.9%)

SELECT * FROM gdpr.customers_orders_with_notes;
use gdpr;

-- STEP 1 — Preview: compare original vs noised values
Select order_value_eur as original_value,
       Round(order_value_eur *(0.95 + Rand() *0.10),2) as noised_value,
       Round((order_value_eur *(0.95 + Rand() *0.10) - order_value_eur) / order_value_eur*100, 2) as dif_percent
From customers_orders_with_notes
limit 15;

-- STEP 2 — Verify: run the same query twice and see different results
-- Unlike SHA2 (deterministic), RAND() gives different output each time.
-- This is intentional: if the noise were deterministic, an attacker could
-- reverse-engineer the original value.
-- NOTE: just re-execute STEP 1 and compare — values will differ.
Select order_value_eur as original_value,
       Round(order_value_eur *(0.95 + Rand() *0.10),2) as noised_value,
       Round((order_value_eur *(0.95 + Rand() *0.10) - order_value_eur) / order_value_eur*100, 2) as dif_percent
From customers_orders_with_notes
limit 15;
-- the result always is different

-- STEP 3 — Statistical comparison: do the aggregates survive the noise?
-- This is the key test. If mean, median, and total are close before and
-- after, the noise is doing its job: protecting individuals without
-- distorting the overall picture.
Select Count(order_value_eur) as num_orders,
	   Round(Avg(order_value_eur),2) as Avg_value,
       Round(Max(order_value_eur),2) as Max_value,
       Round(min(order_value_eur),2) as Min_value,
       Round(sum(order_value_eur),2) as Total_value
From customers_orders_with_notes

union all

Select Count(order_value_eur) as num_orders,
	   Round(Avg(order_value_eur *(0.95 + Rand()*0.10)),2) as Avg_value,
       Round(Max(order_value_eur *(0.95 + Rand()*0.10)),2) as Max_value,
       Round(min(order_value_eur*(0.95 + Rand()*0.10)),2) as Min_value,
       Round(sum(order_value_eur*(0.95 + Rand()*0.10)),2) as Total_value
From customers_orders_with_notes;


-- STEP 4 — Statistical comparison by country
-- Check that the noise preserves relative differences between countries.
-- If Germany had higher avg spend than Spain before noise, it should still
-- be higher after (approximately).
Select country,
		Round(Avg(order_value_eur),2) as Avg_value,
        Round(Avg(order_value_eur*(0.95 + Rand()*0.10)),2) as Avg_noise_value,
        Round(
			ABS(Avg(order_value_eur * (0.95 + Rand()*0.10)) - AVG(order_value_eur))
            / AVG(order_value_eur) *100
            ,2) as percent_variablility
From customers_orders_with_notes
group by country
order by country;
-- I use ABS (absolute value) only to know the deviation




