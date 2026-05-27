-- QUERYs view_demographic_analysis --

SELECT * FROM gdpr.view_demographic_analysis;

-- 1¿Cuántos registros hay por país? Ordena de mayor a menor.
-- 1. How many records are there per country? Order from highest to lowest.
Select country,
	   count(*) as total_registers
From view_demographic_analysis
group by country
order by total_registers desc;
       
-- 2¿Qué categorías de producto aparecen en la tabla?
-- 2. Which product categories appear in the table?
Select product_category,
	   count(*) as total
From view_demographic_analysis
group by product_category;

-- 3¿Cuál es el total_revenue acumulado por país? Ordena de mayor a menor.
-- 3. What is the cumulative total_revenue per country? Order from highest to lowest.
Select country,
	   Round(Sum(total_revenue),2) as total_acumulado
From view_demographic_analysis
group by country
order by total_acumulado desc;


-- 4¿Qué género tiene el mayor avg_order_value promedio?
-- 4. Which gender has the highest average avg_order_value?
Select gender,
	   Round(Sum(total_revenue),2) as sum_revenue
From view_demographic_analysis
group by gender
order by sum_revenue desc;


-- 5¿Cuántos pedidos totales (n_orders) se hicieron en España?
-- 5. How many total orders (n_orders) were placed in Spain?
Select country,
	   sum(n_orders) as total_orders
from view_demographic_analysis
group by country
having country = 'Spain';

-- 6¿Qué categoría de producto genera más revenue por país?
-- 6. Which product category generates the most revenue per country?
with cat_rev as	(Select product_category, country,
		   Round(sum(total_revenue),2) as sum_revenue,
		   row_number() over(partition by country  order by sum(total_revenue) desc) as categoria
	From view_demographic_analysis
	Group by product_category, country)
Select product_category, country,sum_revenue
From cat_rev
where categoria = 1
order by sum_revenue desc;

-- 7¿Cuál es el % de revenue que aporta cada categoría sobre el total global?
-- 7. What is the % of revenue that each category contributes to the global total?
Select product_category,
	Round(Sum(total_revenue)*100 / Sum(Sum(total_revenue)) over(),2) as sum_revenue
from view_demographic_analysis
group by product_category;
	   

-- 8¿En qué rango de edad se concentra el mayor número de pedidos global?
-- 8. Which age range has the highest number of orders globally?
Select age_range, Sum(n_orders) as sum_num_orders
From view_demographic_analysis
group by age_range
order by sum_num_orders desc
limit 1;


-- 9Para cada país, ¿qué género genera más revenue? Muestra país, género y revenue.
-- 9. For each country, which gender generates the most revenue? Show country, gender and revenue.
with cgr as	(Select country, gender, Round(sum(total_revenue),2) as sum_total_revenue,
			row_number() over(partition by country order by sum(total_revenue) desc) as clasificacion
	From view_demographic_analysis
	group by country, gender)
Select country, gender,sum_total_revenue
From cgr
where clasificacion = 1
order by sum_total_revenue desc;



-- 10Rankea países por revenue. Muestra la diferencia vs el país anterior con LAG.
-- 10. Rank countries by revenue. Show the difference vs the previous country using LAG.
with rev_country as (Select country,
			   Round(sum(total_revenue),2) as country_revenue
				From view_demographic_analysis
				group by country
				order by country_revenue desc)

Select Rank() over(order by country_revenue) as ranking,country,
		country_revenue,		
        Lag(country_revenue) over(order by country_revenue) as prev_country_revenue
From rev_country
group by country;
