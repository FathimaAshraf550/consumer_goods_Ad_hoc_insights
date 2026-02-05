/*Provide the list of markets in which customer  "Atliq  Exclusive"  operates its 
business in the  APAC  region. */
SELECT DISTINCT market
FROM dim_customer
WHERE customer='Atliq Exclusive' AND region='APAC';

/* What is the percentage of unique product increase in 2021 vs. 2020? The 
final output contains these fields, 
unique_products_2020 
unique_products_2021 
percentage_chg */
WITH c1 AS(
SELECT COUNT(DISTINCT product_code) AS unique_products_2020,fiscal_year
FROM fact_sales_monthly
WHERE fiscal_year=2020),
c2 AS(
SELECT COUNT(DISTINCT product_code) AS unique_products_2021,fiscal_year
FROM fact_sales_monthly 
WHERE fiscal_year=2021)
SELECT unique_products_2020,unique_products_2021,
ROUND((unique_products_2021-unique_products_2020)*100/unique_products_2020,1) AS percentage_change
FROM c1
CROSS JOIN c2;

/*  Provide a report with all the unique product counts for each  segment  and 
sort them in descending order of product counts. The final output contains 
2 fields, 
segment 
product_count*/
SELECT DISTINCT segment,COUNT(DISTINCT product_code) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;


/*  Follow-up: Which segment had the most increase in unique products in 
2021 vs 2020? The final output contains these fields, 
segment 
product_count_2020 
product_count_2021 
difference*/
WITH c1 AS(
SELECT DISTINCT p.segment,COUNT(DISTINCT p.product_code) AS product_count_2020,f.fiscal_year
FROM dim_product p
JOIN fact_sales_monthly f
USING (product_code)
WHERE f.fiscal_year=2020
GROUP BY p.segment),
c2 AS(
SELECT DISTINCT p.segment,COUNT(DISTINCT p.product_code) AS product_count_2021,f.fiscal_year
FROM dim_product p
JOIN fact_sales_monthly f
USING (product_code)
WHERE f.fiscal_year=2021
GROUP BY p.segment,f.fiscal_year)
SELECT c1.segment,product_count_2020,
product_count_2021,
(product_count_2021-product_count_2020)AS difference
FROM c1
JOIN c2
ON c1.segment=c2.segment
ORDER BY difference DESC;


/* Get the products that have the highest and lowest manufacturing costs. 
The final output should contain these fields, 
product_code 
product 
manufacturing_cost */
SELECT m.product_code,p.product,m.manufacturing_cost
FROM fact_manufacturing_cost m
JOIN dim_product p
ON m.product_code=p.product_code
WHERE manufacturing_cost IN
((SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost),
(SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost));
 
 
/*  Generate a report which contains the top 5 customers who received an 
average high  pre_invoice_discount_pct  for the  fiscal  year 2021  and in the 
Indian  market. The final output contains these fields, 
customer_code 
customer 
average_discount_percentage*/
SELECT c.customer_code,c.customer,ROUND(AVG(pre_invoice_discount_pct),4)AS avg_discount_pct
FROM dim_customer c
JOIN fact_pre_invoice_deductions p
ON c.customer_code=p.customer_code
WHERE p.fiscal_year=2021 AND market='India'
GROUP BY c.customer_code,c.customer
ORDER BY avg_discount_pct DESC
LIMIT 5;


/* Get the complete report of the Gross sales amount for the customer  “Atliq 
Exclusive”  for each month  .  This analysis helps to  get an idea of low and 
high-performing months and take strategic decisions. 
The final report contains these columns: 
Month 
Year 
Gross sales Amount */
SELECT monthname(f.date)AS month,f.fiscal_year,
ROUND(SUM(f.sold_quantity*g.gross_price),1) AS gross_sales_amount
FROM fact_sales_monthly f
JOIN fact_gross_price g
ON f.product_code=g.product_code AND f.fiscal_year=g.fiscal_year
JOIN dim_customer c
ON c.customer_code=f.customer_code
WHERE c.customer='Atliq Exclusive'
GROUP BY f.date,f.fiscal_year;


/*In which quarter of 2020, got the maximum total_sold_quantity? The final 
output contains these fields sorted by the total_sold_quantity, 
Quarter 
total_sold_quantity */
SELECT 
CASE 
WHEN MONTH(date) IN(9,10,11)
THEN 'Q1'
WHEN MONTH(date) IN(12,1,2)
THEN 'Q2'
WHEN MONTH(date) IN(3,4,5)
THEN 'Q3'
WHEN MONTH(date) IN(6,7,8)
THEN 'Q4'
ELSE 'invalid' 
END AS quarter,SUM(sold_quantity) AS total_quantity
FROM fact_sales_monthly
WHERE fiscal_year=2020
GROUP BY quarter
ORDER BY total_quantity DESC;


/* Which channel helped to bring more gross sales in the fiscal year 2021 
and the percentage of contribution?  The final output  contains these fields, 
channel 
gross_sales_mln 
percentage */
WITH c1 AS(
SELECT DISTINCT c.channel,ROUND(SUM(g.gross_price*f.sold_quantity)/1000000,1) AS gross_sales_mln
FROM dim_customer c
JOIN fact_sales_monthly f
ON c.customer_code=f.customer_code
JOIN fact_gross_price g 
ON g.product_code=f.product_code
WHERE f.fiscal_year=2021
GROUP BY c.channel)
SELECT channel,gross_sales_mln,
ROUND((gross_sales_mln)*100/SUM(gross_sales_mln) OVER(),1)AS percentage
FROM c1
GROUP BY channel
ORDER BY gross_sales_mln DESC;


/* Get the Top 3 products in each division that have a high 
total_sold_quantity in the fiscal_year 2021? The final output contains these 
fields, 
division 
product_code 
product 
total_sold_quantity 
rank_order */
WITH top_product AS(
SELECT p.division,p.product_code,p.product,p.variant,
SUM(s.sold_quantity) AS total_sold_quantity,
dense_rank()over(partition by division ORDER BY SUM(s.sold_quantity)DESC )AS rank_order
FROM dim_product p
JOIN fact_sales_monthly s
ON p.product_code=s.product_code
WHERE s.fiscal_year=2021
GROUP BY p.division,p.product_code,p.product)
SELECT division,product_code,CONCAT(product," ",variant) AS product,
total_sold_quantity,rank_order
FROM top_product
WHERE rank_order<4;

