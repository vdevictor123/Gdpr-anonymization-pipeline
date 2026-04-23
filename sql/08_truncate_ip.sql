-- 08_truncate_ip.sql
--
-- Technique: IP TRUNCATION (zero out last octets)
-- Column:    ip_address
--
-- WHY:
--   A full IP address can identify a specific device (and therefore a person).
--   Combined with timestamps, it acts as a digital fingerprint.
--   The GDPR explicitly classifies IP addresses as personal data.
--   Zeroing out the last two octets reduces the IP to a network/region
--   identifier, which is useful for geographic analysis but cannot
--   pinpoint an individual.
--
-- HOW:
--   Extract the first two octets (before the second dot), append '.0.0'.
--   Uses SUBSTRING_INDEX, which splits a string by a delimiter.
--
-- EXAMPLE:
--   Original  : 192.168.45.123
--   Truncated : 192.168.0.0

SELECT * FROM gdpr.customers_orders_with_notes;

-- STEP 1 — Preview: compare original vs truncated
Select ip_address as original_ip,
	   SUBSTRING_INDEX(ip_address, '.',2) as trucantex_ip
From customers_orders_with_notes;

Select ip_address as original_ip,
	   Concat(
	   SUBSTRING_INDEX(ip_address, '.',2),
       '.0.0' ) as concat_truncate
From customers_orders_with_notes;

-- STEP 2 — Privacy gain: unique values before vs after
Select Count(ip_address) as original_ip,
	   count(Concat(
	   SUBSTRING_INDEX(ip_address, '.',2),
       '.0.0' )) as concat_truncate
From customers_orders_with_notes;
-- Its works

-- STEP 3 — Analytical use: orders by network prefix (regional analysis)
-- This type of analysis STILL WORKS after truncation.
Select Concat(
	   SUBSTRING_INDEX(ip_address, '.',2),
       '.0.0' ) as concat_truncate,
       Count(*) as number_orders
From customers_orders_with_notes
Group by concat_truncate
order by Count(*)  desc; 


