SELECT * FROM gdpr.customers_orders_with_notes;
use gdpr;
-- 10_full_anonymization_pipeline.sql
--
-- This is the final script of the SQL anonymization toolkit.
-- It combines ALL techniques from files 02-08 into a single pipeline that
-- transforms the raw dataset into a fully anonymized table, plus creates
-- purpose-limited analytical views for specific use cases.
--
-- PIPELINE SUMMARY:
--   full_name        → SUPPRESSED (not exported)
--   email            → Partial masking (first 2 chars + domain)
--   phone            → Suffix masking (last 4 chars only)
--   customer_id      → SHA2 hashing (irreversible, deterministic)
--   birth_date       → Generalized to 10-year age range
--   postal_code      → Generalized to first 2 characters
--   street_address   → SUPPRESSED (not exported)
--   card_last4       → SUPPRESSED (not exported)
--   order_value_eur  → Noise injection (±5% uniform random)
--   ip_address       → Truncated (last 2 octets zeroed)
--   customer_notes   → Kept for Ollama processing in Phase 4
--   order_id         → Kept (low sensitivity)
--   gender           → Kept (low sensitivity)
--   country          → Kept (low sensitivity)
--   city             → Kept (low sensitivity)
--   payment_method   → Kept (low sensitivity)
--   order_date       → Kept (medium — could be generalized to month)
--   product_category → Kept (low sensitivity)
--   device_type      → Kept (low sensitivity)
--   customer_segment → Kept (low sensitivity)
--
-- ARCHITECTURE NOTE:
--   In addition to the full anonymized table, this script creates
--   purpose-limited analytical views. Instead of one universal table
--   that tries to serve all use cases (and carries combinatorial
--   k-anonymity risks), each view contains ONLY the columns needed
--   for a specific analytical purpose. This follows the GDPR principle
--   of data minimization (Article 5(1)(c)): "personal data shall be
--   limited to what is necessary in relation to the purposes for which
--   they are processed."

-- PART 1: FULL ANONYMIZED TABLE
-- All techniques applied simultaneously
DROP TABLE IF EXISTS customers_orders_anonymized;

CREATE TABLE customers_orders_anonymized AS
Select
	-- id 
	order_id,
    sha2(customer_id,256) as customer_id_hashed,
    -- email
	Case when Locate('@', email) <= 3
			then concat('***', substring(email,locate('@',email)))
         else concat(substring(email,1,2),
					 repeat('*', locate('@',email)-3),
                     substring(email, locate('@',email)))
		 End as email_masked,
	-- phone
    Case when Char_length(phone) <= 4
			then concat(repeat('*', char_length(phone)))
		else concat(repeat('*',char_length(phone) -4),
					substring(phone, -4))
		end as phone_masked,
	-- birth_date
		Concat(floor(timestampdiff(year, birth_date, curdate())/10)*10,
        '-',
        floor(timestampdiff(year, birth_date, curdate())/10)*10 +9)
        as age_range,
	-- postal_code
		concat(substring(postal_code,1,2),
			   repeat('*', char_length(postal_code) -2)) 
		as postal_code_general,
	-- ip_adress
		concat(substring_index(ip_address,'.',2),
			   '.0.0')
		as ip_truncated,
	-- order_value_eur 
		Round(order_value_eur * (0.95 + rand()*0.10), 2)
        as order_value_random,
	-- low sensibility:
	gender,
	country,
	city,
	payment_method,
	order_date,
	product_category,
	device_type,
	customer_segment,
    
	
    -- Unstructured for OLLAMA (phase 4)
    customer_notes
    
From customers_orders_with_notes;
	

		













