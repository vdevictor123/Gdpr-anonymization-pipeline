-- 09_k_anonymity_check.sql
--
-- Technique: K-ANONYMITY VERIFICATION
-- Columns:   gender, country, age_range, postal_prefix (quasi-identifiers)
--
-- WHY:
--   Individual anonymization techniques (masking, hashing, generalization)
--   protect single columns. But an attacker does not look at one column —
--   they COMBINE multiple columns to narrow down individuals.
--   K-anonymity checks whether any combination of quasi-identifiers
--   creates a group smaller than K people. If it does, those people
--   are at risk of re-identification.
--
-- WHAT ARE QUASI-IDENTIFIERS?
--   Columns that are not direct identifiers (like name or email) but
--   can be combined to identify someone. In our dataset:
--   - gender (M/F)
--   - country (6 countries)
--   - age_range (generalized birth_date)
--   - postal_prefix (generalized postal_code)
--
-- HOW:
--   GROUP BY all quasi-identifiers, count people per group.
--   If any group has fewer than K people → K-anonymity is violated.
--
-- INDUSTRY STANDARD: K = 5 minimum, K = 10 recommended.

SELECT * FROM gdpr.customers_orders_with_notes;

-- STEP 1 — Set K threshold and check with 2 quasi-identifiers (gender + country)
-- Simple first: only 2 columns combined. Should be safe.
Select country,
	   gender,
       Count(distinct customer_id) as num_people
From customers_orders_with_notes
group by country, gender
having Count(distinct customer_id) < 5
order by num_people;
-- 0 columns (no groups les 5 num_people) 

-- STEP 2 — Add age_range (3 quasi-identifiers: gender + country + age_range)
-- More columns = smaller groups = higher risk.
Select country,
	   gender,
       concat(Floor(timestampdiff(year, birth_date, Curdate())/10)*10,
       '-', 
       Floor(timestampdiff(year, birth_date, curdate())/10)*10 +9) as age_range,
       Count(distinct customer_id) as num_people
From customers_orders_with_notes
group by country, gender, age_range
having Count(distinct customer_id) < 5
order by num_people;
-- K-anonymity check with K=5 on 3 quasi-identifiers (gender + country + age_range) found 18 violating groups, concentrated in the 10-19 age range
-- This is expected in a synthetic dataset of 5,000 rows
-- In production with larger volumes, these groups would naturally grow above the threshold

-- STEP 3 — Full check: 4 quasi-identifiers
-- (gender + country + age_range + postal_prefix)
-- This is the strictest test. More quasi-identifiers = smaller groups.
Select country,
	   gender,
       concat(floor(timestampdiff(year, birth_date, curdate())/10)*10,
       '-',
       floor(timestampdiff(year,birth_date, curdate())/10)*10 +9) as age_range,
       substring(postal_code,1,2) as generalize_postal_code,
       count(distinct customer_id) as num_people
From customers_orders_with_notes
group by country, gender, age_range, generalize_postal_code
having count(distinct customer_id) < 5
order by num_people;

-- STEP 4 — Summary: how many groups violate K-anonymity at each level?
-- This gives you the big picture in one table.
Select '2 quasi-id (gender + country)' as test,
	   Count(*) as violating_groups
from(
	Select gender,
		   country,
           Count(distinct customer_id) as num_people
	From customers_orders_with_notes
    group by gender, country
    having count(distinct customer_id) < 5
    ) as T1

union all

Select '3 quasi-id (gender + country + age_range)' as test,
		Count(*) as violation_group
From(
	Select gender, country, count(distinct customer_id) as num_people,
    Concat(floor(timestampdiff(year, birth_date, curdate())/10)*10,
    '-',
    floor(timestampdiff(year,birth_date, curdate())/10)*10 +9) as age_group
    From customers_orders_with_notes
    group by gender, country, age_group
    having count(distinct customer_id) < 5) as T2
    
union all

Select '4 quasi-id (gender + country + age_range + posta,_code)' as test,
	   Count(*) as violation_group
From(
		Select gender, country, count(distinct customer_id) as num_people,
    Concat(floor(timestampdiff(year, birth_date, curdate())/10)*10,
    '-',
    floor(timestampdiff(year,birth_date, curdate())/10)*10 +9) as age_group,
    substring(postal_code,1,2) as general_postal_code
    From customers_orders_with_notes
    group by gender, country, age_group, general_postal_code
    having count(distinct customer_id) < 5) as T3;
    
-- CONCLUSION --
-- The k-anonymity check revealed that applying all anonymization techniques on a single flat table still leaves combinatorial vulnerabilities
-- — 1,085 groups with fewer than 5 individuals when using 4 quasi-identifiers. 
-- This is a known limitation of flat-table anonymization.
-- The recommended production approach is purpose-limited analytical views:
-- instead of one universal anonymized table, create specific views containing only the columns needed for each analytical use case.
-- This reduces the quasi-identifier space and dramatically improves k-anonymity compliance while maintaining full analytical utility for each specific purpose    
