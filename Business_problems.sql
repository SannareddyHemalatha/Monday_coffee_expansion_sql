-- Q1. Coffee Consumers Count
-- How many people in each city are estimated to consume coffee, given that 25% of the population does?

select 
city_name,
round((population*0.25)/1000000,2) as coffee_consumers_in_mil,
city_rank 
from city 
order by 2 desc;

-- Q2 - Total Revenue from Coffee Sales
-- What is the total revenue generated from coffee sales across all cities in the last quarter of 2023?

select 
sum(total) as total_revenue 
from sales 
where extract(year from sale_date)=2023 and extract(quarter from sale_date)=4;

select 
ci.city_name,
sum(total) as total_revenue
from sales s
join customers cus
on s.customer_id=cus.customer_id
join city ci
on cus.city_id=ci.city_id
where extract(year from sale_date)=2023 and extract(quarter from sale_date)=4
group by ci.city_name
order by total_revenue desc;

-- Q.3
-- Sales Count for Each Product
-- How many units of each coffee product have been sold?

select 
product_name,
sum(total) as total
from sales s
join products p
on p.product_id=s.product_id
group by product_name
order by total desc;

select p.product_name,count(s.product_id) as total_units_sold from sales s
join products p
on p.product_id=s.product_id
group by s.product_id
order by total_units_sold desc;

-- Q.4
-- Average Sales Amount per City
-- What is the average sales amount per customer in each city?

select 
c.city_name,
sum(s.total) total_revenue,
count(distinct s.customer_id) as total_customers,
round(sum(s.total)/count(distinct s.customer_id),2) as avgsales_per_customer
from city c
join customers cus
on c.city_id=cus.city_id
join sales s
on s.customer_id=cus.customer_id
group by c.city_name
order by avgsales_per_customer desc;

-- -- Q.5
-- City Population and Coffee Consumers (25%)
-- Provide a list of cities along with their populations and estimated coffee consumers.
-- return city_name, total current cx, estimated coffee consumers (25%)

select 
city_name,
population,
round((population*0.25)/1000000,2) as est_coffee_consumers,
count(cus.customer_id) as total_customers
from city c
join customers cus 
on c.city_id=cus.city_id
group by c.city_id
order by est_coffee_consumers desc;

- -- Q6
-- Top Selling Products by City
-- What are the top 3 selling products in each city based on sales volume?

select * from(
select 
c.city_name,
p.product_name,
count(s.sale_id) total_units_sold,
dense_rank() over(partition by c.city_name order by count(s.sale_id) desc) as ranking
from sales s
join products p
on s.product_id=p.product_id
join customers cus
on s.customer_id = cus.customer_id
join city c 
on cus.city_id=c.city_id
group by c.city_name,p.product_name
) as ranking_table
where ranking<=3;

-- Q.7
-- Customer Segmentation by City
-- How many unique customers are there in each city who have purchased coffee products?

select c.city_name,count(distinct cus.customer_id) as unique_customers from city c
left join customers cus
on c.city_id=cus.city_id
join sales s
on s.customer_id=cus.customer_id
join products p
on p.product_id=s.product_id
where s.product_id in (1,2,3,4,5,6,7,8,9,10,11,12,13,14)
group by c.city_id
order by unique_customers desc;

-- -- Q.8
-- Average Sale vs Rent
-- Find each city and their average sale per customer and avg rent per customer

select 
c.city_name,
round(sum(s.total)/count(distinct s.customer_id),2) as avgsales_per_customer,
round(c.estimated_rent/count(distinct s.customer_id),2) as avgrent_per_customer
from city c
join customers cus
on c.city_id=cus.city_id
join sales s
on s.customer_id=cus.customer_id
group by c.city_name,c.estimated_rent
order by c.city_name;

-- Q.9
-- Monthly Sales Growth
-- Sales growth rate: Calculate the percentage growth (or decline) in sales over different time periods (monthly)
-- by each city

WITH
monthly_sales
AS
(
	SELECT 
		ci.city_name,
		EXTRACT(MONTH FROM sale_date) as month,
		EXTRACT(YEAR FROM sale_date) as YEAR,
		SUM(s.total) as total_sale
	FROM sales as s
	JOIN customers as c
	ON c.customer_id = s.customer_id
	JOIN city as ci
	ON ci.city_id = c.city_id
	GROUP BY 1, 2, 3
	ORDER BY 1, 3, 2
),
growth_ratio
AS
(
		SELECT
			city_name,
			month,
			year,
			total_sale as cr_month_sale,
			LAG(total_sale, 1) OVER(PARTITION BY city_name ORDER BY year, month) as last_month_sale
		FROM monthly_sales
)

SELECT
	city_name,
	month,
	year,
	cr_month_sale,
	last_month_sale,
	ROUND(
		(cr_month_sale-last_month_sale)/last_month_sale * 100, 2) as growth_ratio

FROM growth_ratio
WHERE 
	last_month_sale IS NOT NULL;
    
-- Q.10
-- Market Potential Analysis
-- Identify top 3 city based on highest sales, return city name, total sale, total rent, total customers, estimated coffee consumer

with city_table as(
select 
c.city_name,
sum(s.total) as total_revenue,
round(sum(s.total)/count(distinct s.customer_id),2) as avg_sale_per_customer,
count(distinct s.customer_id) as total_customers
from sales s 
join customers cus 
on cus.customer_id=s.customer_id
join city c
on c.city_id=cus.city_id
group by city_name
order by 2 desc
),
city_rent as (
 select 
 city_name,
 estimated_rent,
 round((population*0.25)/1000000,2) as est_coffee_consumers
 from city
)
SELECT 
	cr.city_name,
	ct.total_revenue,
	cr.estimated_rent as total_rent,
	ct.total_customers,
	est_coffee_consumers,
	ct.avg_sale_per_customer,
	ROUND(
		cr.estimated_rent/ct.total_customers, 2) as avg_rent_per_customer
FROM city_rent as cr
JOIN city_table as ct
ON cr.city_name = ct.city_name
ORDER BY 2 DESC limit 3