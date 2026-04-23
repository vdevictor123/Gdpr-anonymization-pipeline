
-- Masked email --
use gdpr;

SELECT * FROM gdpr.customers_orders_with_notes;

Select email as original_email,
		concat(substring(email,1,2),
		repeat('*', locate('@', email) -3),
		substring(email,locate('@',email))
) as masket_email
from customers_orders_with_notes
where email is not null
limit 10;


