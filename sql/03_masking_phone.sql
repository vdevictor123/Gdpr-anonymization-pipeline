-- 03_masking_phone.sql
--
-- Technique: SUFFIX MASKING (keep last N digits)
-- Column:    phone
--
-- WHY:
--   Phone numbers are direct identifiers under GDPR. A leaked number enables
--   contact, SIM swap attacks, and cross-referencing against other breaches.
--   Unlike emails, phone numbers have NO reliable separator character
--   (formats vary by country: +34 912..., (0174)-164776, 255.901.1375x...)
--   so we cannot use LOCATE. Instead we mask based on length.
--
-- HOW:
--   Show only the LAST 4 digits, replace everything before with asterisks.
--   The length of the mask adapts to the phone length (no hardcoded numbers).
--
-- EXAMPLE:
--   Original : +34 912 345 678
--   Masked   : ***********5678

SELECT * FROM gdpr.customers_orders_with_notes;

-- I left just the las 4 phone number
Select phone as original_phone,
	concat(repeat ('*', CHAR_LENGTH(phone) -4),
		  substring(phone, -4))
from customers_orders_with_notes
where phone is not null
limit 10;
        
-- Is there a phone number in my records with fewer than 4 characters?
-- Shoud be 0
SELECT
    phone,
    CHAR_LENGTH(phone) AS phone_length
from customers_orders_with_notes
Where phone is not null
  And CHAR_LENGTH(phone) < 4
Limit 5;

-- If we have phone numbers lenght les than 4 we have to apply this query
SELECT phone as original_phone,
	   case
			when char_length(phone) <= 4 then repeat('*', char_length(phone))
		    else concat(repeat('*', char_length(phone) -4),
				 substring(phone,-4)) End as masked_phone
 From customers_orders_with_notes
 where phone is not null
 limit 10;
 
 
 -- Show masking behaviour across different country formats
 Select
	    phone as original_phone,
        case when char_length(phone) <= 4 then repeat('*', char_length(phone))
			 else concat(repeat('*', char_length(phone) -4),
				  substring(phone, -4)) end as masked_phone,
		COUNTRY AS COUNTRY
from customers_orders_with_notes
where phone is not null
group by phone, country
limit 10;


-- Automatic security test. It checks that your masking doesn't leave any phone numbers unmasked.
Select
	  COUNT(*) AS leaky_rows
from customers_orders_with_notes
where phone is not null
  and CHAR_LENGTH(
      replace(CONCAT(repeat('*', CHAR_LENGTH(phone) - 4), SUBSTRING(phone, -4)),'*','')
      ) > 4;
 

 
 

 
 
 
 