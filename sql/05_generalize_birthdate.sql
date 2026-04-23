
-- 05_generalize_birthdate.sql
--
-- Technique: TEMPORAL GENERALIZATION
-- Column:    birth_date
--
-- WHY:
--   An exact birth date is a quasi-identifier. On its own it seems harmless,
--   but combined with gender + country + postal_code it can narrow down a
--   person to a very small group (or even a single individual).
--   Replacing the exact date with a 10-year age range drastically increases
--   the size of each group, making re-identification much harder.
--
-- HOW:
--   1. Calculate exact age from birth_date
--   2. Round down to the nearest decade (FLOOR(age / 10) * 10)
--   3. Express as a range: "30-39", "40-49", etc.
--
-- EXAMPLE:
--   Original : 1961-08-10  (age 64)
--   Generalized : 60-69

SELECT * FROM gdpr.customers_orders_with_notes;

-- STEP 1 — Preview: calculate exact age, then generalize to decade range
Select birth_date,
	   timestampdiff(YEAR, birth_date, CURDATE()) as exact_age,
       Floor(timestampdiff(YEAR,birth_date, CURDATE()) /10)*10 as decadate_start,
       Concat(floor(timestampdiff(YEAR, birth_date, CURDATE()) /10) *10,
			  '-',
			  floor(timestampdiff(YEAR,birth_date, CURDATE()) /10)*10 +9) as range_age
From customers_orders_with_notes
where birth_date is not null
limit 10;

-- STEP 2 — Distribution: how many customers fall into each age range?
-- This is the kind of analysis that STILL WORKS after generalization.
Select concat(
	floor(timestampdiff(YEAR, birth_date, CURDATE()) /10)*10,
    '-',
    floor(timestampdiff(year,birth_date, CURDATE()) /10)*10 +9) as range_age,
    Count(*) as num_orders,
    Round(AVG(order_value_eur),2) as avg_order_value
From customers_orders_with_notes
where birth_date is not null
group by range_age
order by num_orders desc;

-- STEP 3 — Privacy gain: how many unique values before vs after?
-- Fewer unique values = harder to re-identify someone.
Select Count(distinct(birth_date)) as unique_dates,
	   Count(distinct(concat(floor(timestampdiff(Year,birth_date, Curdate()) /10)*10,
       '-',
       Floor(timestampdiff(Year, birth_date, curdate())/10)*10 +9))) as unique_age
From customers_orders_with_notes;

-- STEP 4 — Edge case check: are there any unusual ages (< 18 or > 100)?
-- Extreme ages in small groups are a re-identification risk even after
-- generalization (e.g. if only 1 person is in the "90-99" range).
Select concat(
	floor(timestampdiff(YEAR, birth_date, CURDATE()) /10)*10,
    '-',
    floor(timestampdiff(year,birth_date, CURDATE()) /10)*10 +9) as range_age,
    Count(*) as num_orders,
    Round(AVG(order_value_eur),2) as avg_order_value
From customers_orders_with_notes
where birth_date is not null
group by range_age
having count(*) <10
order by range_age;

-- STEP 5 — Validate: the original birth_date should NOT be recoverable
-- from the age range. This query checks that multiple distinct birth_dates
-- map to the same range (i.e. information is genuinely lost).
Select concat(
	floor(timestampdiff(YEAR, birth_date, CURDATE()) /10)*10,
    '-',
    floor(timestampdiff(year,birth_date, CURDATE()) /10)*10 +9) as range_age,
    Count(Distinct birth_date) as num_orders,
    MAX(birth_date) as mlast_date,
    Min(birth_date) as first_date
From customers_orders_with_notes
where birth_date is not null
group by range_age
order by range_age desc;

