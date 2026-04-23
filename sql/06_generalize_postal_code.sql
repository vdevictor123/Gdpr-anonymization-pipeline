-- 06_generalize_postal_code.sql
--
-- Technique: GEOGRAPHIC GENERALIZATION
-- Column:    postal_code
--
-- WHY:
--   A full postal code narrows location to a small area (a few streets).
--   Combined with age range + gender, it can uniquely identify individuals.
--   Keeping only the first 2-3 characters broadens the area to a city or
--   region, protecting individual locations while preserving regional analysis.
--
-- HOW:
--   Keep the first 2 characters, replace the rest with asterisks.
--   This works across all European formats (ES, DE, FR, NL, IE, UK)
--   because the first 2 characters always indicate the broad region.
--
-- EXAMPLES:
--   Spain   : 28045    →  28***
--   Germany : 10115    →  10***
--   France  : 75008    →  75***
--   NL      : 2323LD   →  23****
--   Ireland : N27 7NYE →  N2******
--   UK      : SW1A 1AA →  SW******

SELECT * FROM gdpr.customers_orders_with_notes;

-- STEP 1 — Preview: compare original vs generalized by country
-- Logic:
--   SUBSTRING(postal_code, 1, 2)  →  first 2 characters (the region part)
--   REPEAT('*', CHAR_LENGTH(postal_code) - 2)  →  stars for the rest
-- Same pattern as phone masking, but here we keep the FIRST N, not the LAST N.
Select postal_code as original_pcode,
	   Concat(substring(postal_code,1,2),
	   repeat('*', char_length(postal_code) -2)) as general_pcode
From customers_orders_with_notes
where postal_code is not Null;

-- STEP 2 — Distribution: how many orders per general pcode?
-- This is the type of regional analysis that STILL WORKS after generalization.

Select country,
    substring(postal_code, 1, 2) AS region_prefix,
    Count(*) AS n_orders,
    Round(AVG(order_value_eur), 2) AS avg_order_value
from customers_orders_with_notes
where postal_code is not null
group by country, region_prefix
order by country, n_orders desc
limit 20;

-- STEP 3 — Privacy gain: unique values before vs after
-- The bigger the reduction, the more privacy we gain.
Select
	Count(Distinct(postal_code)) as unique_codes,
    Count(distinct substring(postal_code,1,2)) as unique_genralized
from customers_orders_with_notes;

-- STEP 4 — Edge case check: any region prefix with fewer than 10 people?
-- Small groups = re-identification risk, same concept as birthdate STEP 4.
Select country,
	 substring(postal_code,1,2) as region_prefix,
     count(customer_id) as total_people
from customers_orders_with_notes
group by country, region_prefix
having count(customer_id) < 10
order by count(customer_id);

-- STEP 5 — Validate: generalized code must not leak the full postal code
-- Check that multiple distinct original codes map to the same prefix.
-- If every prefix has > 1 original code mapping to it, information is lost.
Select substring(postal_code,1,2) as region_prefix,
     count(distinct postal_code) as unique_postal,
     max(postal_code) as example_max,
     min(postal_code) as example_min
from customers_orders_with_notes
group by region_prefix
order by unique_postal asc
limit 15;

-- Reducing postal codes from two characters to one: `SUBSTRING(postal_code, 1, 1)` → more groups, more protection, less analytical detail.
-- Suppressing postal codes from groups with `unique_postal = 1` → replacing them with `NULL` or `REDACTED`.



