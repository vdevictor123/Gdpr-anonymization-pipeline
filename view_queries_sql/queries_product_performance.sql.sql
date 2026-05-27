SELECT * FROM gdpr.view_product_performance;


-- 1-¿Cuál es la categoría de producto con mayor total_revenue?
-- 1. Which product category has the highest total_revenue?
select product_category, round(sum(total_revenue),2) as sum_total
From view_product_performance
group by product_category
order by sum_total desc;

-- 2- ¿Cuántos pedidos totales (n_orders) hay por device_type?
-- 2. How many total orders (n_orders) are there per device_type?
Select device_type, sum(n_orders) as total_n_orders
from view_product_performance
group by device_type
order by total_n_orders desc;

-- 3-¿Cuál es el avg_order_value máximo y mínimo de toda la tabla?
-- 3. What is the maximum and minimum avg_order_value in the entire table?
Select max(avg_order_value) as max_avg, min(avg_order_value) as min_avg
from view_product_performance;

-- 4-Lista todas las combinaciones donde min_order_value sea mayor de 30. 
-- 4. List all combinations where min_order_value is greater than 30.
select product_category,device_type, payment_method, n_orders, avg_order_value, total_revenue, min_order_value, max_order_value
From view_product_performance
where min_order_value > 30
order by min_order_value desc;

-- 5-¿Qué método de pago tiene el mayor avg_order_value promedio entre todas sus combinaciones?
-- 5. Which payment method has the highest average avg_order_value across all its combinations?
Select payment_method, round(avg(avg_order_value),2) as avg_avg_order
From view_product_performance
group by payment_method
order by avg(avg_order_value) desc
limit 1;


-- 6-¿Qué combinación (categoría + device_type) tiene el mayor revenue? Muestra el % sobre el total.
-- 6. Which combination (category + device_type) has the highest revenue? Show the % of the total.
Select product_category,
	   device_type,
       round(sum(total_revenue),2) as revenue,
       round(sum(total_revenue) *100 / sum(sum(total_revenue)) over(),2) as  prc_revenue            
from view_product_performance
group by product_category, device_type
order by revenue desc;

-- 7-Para cada categoría, calcula el rango de valor (max_order_value − min_order_value). ¿Cuál tiene el rango más alto?
-- 7. For each category, calculate the value range (max_order_value − min_order_value). Which one has the highest range?
Select product_category,
		max(max_order_value) as max_max,
        min(min_order_value) min_min,
		(max(max_order_value) - min(min_order_value)) as value_range
from view_product_performance
group by product_category
order by value_range desc;

-- 8-¿Cuánto revenue genera Klarna vs el resto? Muestra ambos totales y el % de Klarna.
-- 8. How much revenue does Klarna generate vs the rest? Show both totals and Klarna's %.
with grupo_k_r as(Select 
			Case when payment_method = 'Klarna' then 'Klarna'
				 else 'Resto' end as grupo,
			round(sum(total_revenue),2) as sum_revenue                
	from view_product_performance
	group by  grupo)
Select  grupo,sum_revenue, round(sum(sum_revenue) over(),2) as total_sum,
		round(sum_revenue *100 / sum(sum_revenue) over(),2) as prc_total
from grupo_k_r;

-- 9-Rankea cada categoría de producto por revenue dentro de cada device_type. 
-- 9. Rank each product category by revenue within each device_type.
with ranked as (Select device_type, product_category,
					   round(Sum(total_revenue),2) as revenue,
                       dense_rank () over (partition by device_type order by sum(total_revenue) desc) as ranking
                       From view_product_performance
                       group by device_type, product_category)
Select device_type, product_category, revenue, ranking
From ranked;
					   
-- 10-Calcula el revenue acumulado (running total) por categoría, ordenando las combinaciones de mayor a menor n_orders dentro de cada categoría.
-- 10. Calculate the cumulative revenue (running total) per category, ordering combinations from highest to lowest n_orders within each category.
Select product_category, device_type, payment_method, n_orders, total_revenue,
	   round(sum(total_revenue) over(partition by product_category order by n_orders desc ROWS UNBOUNDED PRECEDING),2) as running_total
From view_product_performance
order by product_category, n_orders DESC;
