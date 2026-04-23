
-- 04_hashing_customer_id.sql
--
-- Technique: SHA2 HASHING (one-way, irreversible)
-- Column:    customer_id
--
-- WHY:
--   customer_id is a pseudo-identifier. It does not reveal PII directly,
--   but it can be used to cross-reference this export with internal databases
--   to unmask real customer identities. Hashing breaks that link permanently
--   while preserving the ability to group orders by the same customer.
--
-- HOW:
--   SHA2(customer_id, 256) produces a fixed-length 64-character hex string.
--   Same input always gives the same output (deterministic), but the output
--   cannot be reversed back to the input (one-way).
--
-- KEY PROPERTIES:
--   1. Irreversible  — cannot recover CUST-000764 from the hash
--   2. Deterministic — same customer_id always produces the same hash
--   3. Fixed length  — output is always 64 characters, regardless of input
--   4. Collision-resistant — extremely unlikely that two different inputs
--      produce the same hash
--
-- EXAMPLE:
--   Original : CUST-000764
--   Hashed   : a3f2b8c1... (64 hex characters)

SELECT * FROM gdpr.customers_orders_with_notes;


-- STEP 1 — Preview: compare original vs hashed side by side
Select customer_id as original_id,
	   SHA2(customer_id,256) as hashed_id
from customers_orders_with_notes
limit 10;

-- STEP 2 — Verify DETERMINISM: same customer_id must always produce same hash
-- This query finds customers with multiple orders and checks that the hash
-- is identical across all their orders.
Select customer_id as original_id,
	   SHA2(customer_id, 256) as hashed_id,
       Count(*) as number_orders
from customers_orders_with_notes
group by customer_id
having count(*) > 1
order by Count(*) desc
limit 15;

-- STEP 3 — Verify UNIQUENESS: different customer_ids must produce different hashes
-- If this returns 0, no two different customers share the same hash.
with customer_distinct as 	(Select Count(distinct customer_id) as total
							from customers_orders_with_notes),
	customer_SHA2 as (Select count(distinct SHA2(customer_id,256)) as total_SHA2
		From customers_orders_with_notes)
    
Select (Select total from customer_distinct) - (Select total_SHA2 from customer_SHA2)
from  customers_orders_with_notes;

-- STEP 4 — Verify FIXED LENGTH: every hash should be exactly 64 characters
Select customer_id as original_id,
	   SHA2(customer_id, 256) as hashed_id,
       char_length(SHA2(customer_id, 256)) as len_hashed_id
from customers_orders_with_notes;

-- STEP 5 — Verify IRREVERSIBILITY (conceptual, not a proof)
-- Show that similar inputs produce completely different hashes.
-- Even CUST-000001 and CUST-000002 (one digit apart) have zero resemblance.
-- This is called the "avalanche effect" — a tiny input change flips ~50% of
-- the output bits.

Select 'CUST-000001' AS input_01,
		SHA2('CUST-000001',256) as sha2_input_01,
        'CUST-000002' AS input_02,
        SHA2('CUST-000002',256) as sha2_input_02
From customers_orders_with_notes;
        
-- STEP 6 — Preview: how the anonymized table would look for analytics
-- The hash preserves GROUP BY capability without exposing customer identity.

Select SHA2(customer_id,256) as hashed_id,
	   Count(*) as total_orders,
       Round(Sum(order_value_eur),2) as Total_spend,
       Min(order_value_eur) as Min_value,
       Max(order_value_eur) as Max_value
From customers_orders_with_notes
group by SHA2(customer_id,256)
having Count(*) > 3
order by total_spend desc;
