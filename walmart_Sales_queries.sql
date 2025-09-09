create database walmart_db;

show databases;

use walmart_db;

select * from walmart;

select count(distinct branch) from walmart;

/*Business Problems--*/
/*Q1: Find different payment methods, number of transactions, and quantity sold by payment method*/

select distinct payment_method,
count(*) as no_payments,
sum(quantity) as qty_sold
 from walmart
 group by payment_method;
 
 /*Identify the highest-rated category in each branch
-- Display the branch, category, and avg rating*/
select branch,category,avg_rating
from 
(select branch,category,avg(rating)as avg_rating,rank() over(partition by branch order by avg(rating) desc) as rnk
from walmart
group by branch,category)as ranked
where rnk =1;

/*Q3: Identify the busiest day for each branch based on the number of transactions*/
select branch,no_of_transactions,day_name
from
(SELECT 
    branch,
    COUNT(*) AS no_of_transactions,
    DAYNAME(STR_TO_DATE(`date`, '%d/%m/%y')) AS day_name,
    RANK() OVER (
        PARTITION BY branch 
        ORDER BY COUNT(*) DESC
    ) AS rnk
FROM walmart
GROUP BY 
    branch, 
    DAYNAME(STR_TO_DATE(`date`, '%d/%m/%y')))as ranked
where rnk=1;


/*Q4: Calculate the total quantity of items sold per payment method*/
select sum(quantity),payment_method
from walmart
group by payment_method;

/* Q5: Determine the average, minimum, and maximum rating of categories for each city*/
select avg(rating),min(rating),max(rating),category,city
from walmart
group by city,category;

/*Q6: Calculate the total profit for each category*/
select sum(total*profit_margin) as total_profit,category
from walmart
group by category
order by total_profit  desc;

/*Determine the most common payment method for each branch*/
WITH cte AS (
    SELECT 
        branch,
        payment_method,
        COUNT(*) AS total_trans,
        RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS rnk
    FROM walmart
    GROUP BY branch, payment_method
)
SELECT branch, payment_method AS preferred_payment_method
FROM cte
WHERE rnk = 1;

/* Categorize sales into Morning, Afternoon, and Evening shifts*/
select branch,
case
 when hour(time(time)) <12 then 'Morning'
 when hour(time(time)) between 12 and 17 then 'afternoon'
 else  'evening'
end as shift,
count(*) as num_invoices
from walmart
group by branch,shift
order by branch,num_invoices desc;

/*Identify the 5 branches with the highest revenue decrease ratio from last year to current year (e.g., 2022 to 2023)*/
with revenue_2022 as(
select branch,sum(total) as last_revenue
from walmart
where year(str_to_date(date,'%d/%m/%y'))=2022
group by branch),
revenue_2023 as (
select branch,sum(total) as present_revenue
from walmart
where year(str_to_date(date,'%d/%m/%y'))=2023
group by branch
)
select r22.branch,
r22.last_revenue,
r23.present_revenue,
 ROUND(((r22.last_revenue - r23.present_revenue) / r22.last_revenue) * 100, 2) AS revenue_decrease_ratio
from revenue_2022 as r22 join revenue_2023 as r23
 on r22.branch=r23.branch
 WHERE r22.last_revenue > r23.present_revenue
ORDER BY revenue_decrease_ratio DESC
LIMIT 5;