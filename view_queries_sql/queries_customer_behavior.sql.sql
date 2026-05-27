-- QUERYs view_customer_behavior -- 

SELECT * FROM gdpr.view_customer_behavior;
use gdpr;


-- 1¿Cuántos clientes hay en total?
-- 1. How many customers are there in total?
Select Count(Distinct customer_hash) as num_clientes #for in case we have a duplicates
From view_customer_behavior;

-- 2¿Cuántos clientes hay por segmento (New vs Regular)?
-- 2. How many customers are there per segment (New vs Regular)?
Select Count(customer_segment),
		customer_segment
From view_customer_behavior
where customer_segment in ('New', 'Regular')
group by customer_segment;


-- 3¿Cuál es el gasto total (total_spent) promedio de todos los clientes?
-- 3. What is the average total spend (total_spent) across all customers?
Select Round(avg(total_spent),3) as avg_total
From view_customer_behavior;


-- 4 Muestra los 5 clientes con mayor total_spent.
-- 4. Show the top 5 customers by total_spent.
Select customer_hash,
	sum(total_spent) as sum_total_spend # i did that for if one client buy more than 1 product, sum the totals in just one client
From view_customer_behavior
Group by customer_hash
order by sum_total_spend desc
limit 5;


-- 5¿Cuántos clientes tienen más de 10 pedidos (total_orders > 10)?
-- 5. How many customers have more than 10 orders (total_orders > 10)?
Select count(customer_hash) as total_clients
From view_customer_behavior
where total_orders > 10;

-- 6¿Cuántos clientes hay para cada cantidad de pedidos mayor a 10?
-- 6. How many customers are there for each order count greater than 10?
Select 
	   Count(customer_hash),
       total_orders
From view_customer_behavior
where total_orders > 10
group by total_orders
Order by total_orders desc;


-- 7 ¿Cuál es el avg_order_value medio por segmento? Ordena de mayor a menor.
-- 7. What is the average avg_order_value per segment? Order from highest to lowest.
Select customer_segment,
	   round(avg(avg_order_value),2) as avg_order
from view_customer_behavior
group by customer_segment
order by avg_order desc;

-- 8 ¿Qué % del total de clientes pertenece al segmento 'Regular'?
-- 8. What % of total customers belong to the 'Regular' segment?
Select customer_segment,
	count(*)*100/Sum(count(*)) over() as pct_clients
From view_customer_behavior
group by customer_segment;
    
Select Count(case when customer_segment = 'Regular' then 1 End)
        /Count(*)*100.0 as prc_regular
From view_customer_behavior;

-- 9 ¿Cuántos clientes llevan más de 365 días activos? Muestra también el % sobre el total.
-- 9. How many customers have been active for more than 365 days? Also show the % of the total.
Select count(case when customer_lifespan_days > 365 then 1 end) as num_activos_365,
	   count(case when customer_lifespan_days > 365 then 1 end) / count(*) *100 as prc_clients
from view_customer_behavior;


-- 10 Para cada segmento, ¿cuál es el cliente con mayor total_spent? Muestra segmento, hash y gasto.
-- 10. For each segment, which customer has the highest total_spent? Show segment, hash and spend.
with class as(	
    Select customer_segment,
		customer_hash,
		total_spent,
		row_number() over(partition by customer_segment order by total_spent desc) as clasification
	From view_customer_behavior)
Select customer_segment,
	customer_hash,
	total_spent
From class
where clasification = 1
order by total_spent desc;


-- 11 Calcula el recency de cada cliente: días desde last_order hasta hoy. Muestra los 10 más inactivos.
-- 11. Calculate the recency of each customer: days since last_order until today. Show the 10 most inactive.
Select customer_hash,
	timestampdiff(day, last_order, current_date()) as time_diff
From view_customer_behavior
order by time_diff desc
Limit 10;
