use gdpr;
SELECT * FROM gdpr.view_geo_analysis;
DESCRIBE view_geo_analysis;

-- 1-¿Cuántos pedidos hay por método de pago?
-- 1. How many orders are there per payment method?
Select payment_method,
	   Count(*) as num_orders
From view_geo_analysis
group by payment_method
order by num_orders desc;

-- 2-¿Cuál es el order_value promedio por device_type?
-- 2. What is the average order_value per device_type?
Select device_type,
	   Round(avg(order_value),2) as avg_order_value
From view_geo_analysis
group by device_type
order by avg_order_value desc;
	
-- 3-¿Cuántos pedidos se realizaron desde España?
-- 3. How many orders were placed from Spain?
Select country,
	 count(*) as total_orders
From view_geo_analysis
group by country
having country = 'Spain';

-- 4-Lista los 5 países con más pedidos.
-- 4. List the top 5 countries with the most orders.
Select Rank() over(order by count(*) desc) as Ranking,
       country,	   
	   count(*) as total_orders
From view_geo_analysis
group by country
order by total_orders desc
limit 5;

-- 5-¿Cuántos pedidos desde mobile en Reino Unido?
-- 5. How many orders were placed from mobile in the United Kingdom?
Select country,
	   device_type,
       Count(*) as total_orders
From view_geo_analysis
group by country,device_type
having country= 'United Kingdom' and device_type = 'mobile';


-- 6-¿Qué método de pago genera mayor revenue por país? Muestra los 3 primeros países.
-- 6. Which payment method generates the most revenue per country? Show the top 3 countries.
Select payment_method,
	   country,
	   Round(Sum(order_value),2) as sum_value
From view_geo_analysis
group by payment_method,country
order by sum_value desc
limit 3;
       

-- 7-¿Cuánto revenue se generó por mes? Ordena cronológicamente.
-- 7. How much revenue was generated per month? Order chronologically.
Select date_format(Cast(order_date as date),'%Y-%m') AS mes ,
	   Round(sum(order_value),2) as sum_value
From view_geo_analysis
group by mes
order by mes asc;

-- 8-¿Qué % de pedidos viene de cada device_type?
-- 8. What % of orders comes from each device_type?
with total_device as( Select device_type,
		   count(*) as total_orders
		   From view_geo_analysis
		   group by device_type)
Select device_type,
	   total_orders,
		SUM(sum(total_orders)) over() as sum_total,
	   round(total_orders *100 /SUM(sum(total_orders)) over(),2) as pcr_orders
From total_device
group by device_type, total_orders;


-- 9-Por país, calcula el crecimiento de revenue entre el primer y el último mes con datos.
-- 9. Per country, calculate the revenue growth between the first and last month with data.
with monthly as   (Select country,
			      Date_format(order_date, '%Y-%m') as month,
				  Round(sum(order_value),2) as sum_order
				From view_geo_analysis
				group by country, month),
                
bounds as ( Select country,
				   Min(month) as min_month,
				   Max(month) as max_month
			From monthly
            group by country)

Select b.country, 
	   first_rev.sum_order as first_month_revenue,
	   last_rev.sum_order as last_month_revenue,
       Round(( last_rev.sum_order - first_rev.sum_order) *100 / first_rev.sum_order,2) as comparation_prc
From bounds  as b
join monthly as first_rev
on  b.country = first_rev. country
	and b.min_month = first_rev.month
join monthly as last_rev
on b.country = last_rev.country
	and b.max_month = last_rev.month;
    

-- 10-Detecta ciudades con revenue por encima de la media de su país. Muestra ciudad, país, revenue de ciudad y media del país.
-- 10. Find cities with revenue above their country's average. Show city, country, city revenue and country average.
with sum_city as (Select country, city, sum(order_value) as sum_order_city
					From view_geo_analysis
                    group by country, city),
	 avg_country as (Select country,  avg(sum_order_city) as avg_total
					 From sum_city
					 group by country)
Select s.country, s.city, sum_order_city, avg_total
From sum_city as s
join avg_country as a
on s.country = a.country
where sum_order_city > avg_total
order by s.country;
