/* ----------------------View-------------------------------------*/

create or replace view retail_event as
select c.campaign_name,c.start_date,c.end_date,p.product_name,p.category,f.base_price,f.promo_type,s.store_id,s.city,
sum(f.quantity_sold_before_promo) qty_sold_before_promo,sum(quantity_sold_after_promo) qty_sold_after_promo
from fact_events f
inner join dim_campaigns c on f.campaign_id=c.campaign_id
inner join dim_products p on f.product_code=p.product_code
inner join dim_stores s on f.store_id=s.store_id
group by c.campaign_name,c.start_date,c.end_date,p.product_name,p.category,f.base_price,f.promo_type,s.store_id,s.city;
 /*------------------------------------------over ------------------------------------*/


/*
1 Provide a list of products with a base price greater than 500 and that are featured in promo type of 'BOGOF' (Buy One Get One Free). This information will help 
us identify high-value products that are currently being heavily discounted, which can be useful for evaluating our pricing and promotion strategies
*/
SELECT r.product_name,r.base_price,sum(r.qty_sold_before_promo) qty_sold_bp,sum(r.qty_sold_after_promo) qty_sold_qp 
FROM retail_event r
WHERE r.BASE_PRICE > 500 -- IT WILL ABOVE 500 SHOW
AND r.promo_type ='BOGOF' -- THE PROMO TYPE BOGOF
group by 1,2;


/* 2. Generate a report that provides an overview of the number of stores in each city.
 The results will be sorted in descending order of store counts, allowing us to identify the cities with the highest store presence*/
SELECT e.city, COUNT(DISTINCT e.store_id) AS no_of_store 
FROM retail_event e 
GROUP BY e.city 
ORDER BY no_of_store desc ;

/*
Generate a report that displays each campaign along with the total revenue generated before and after the campaign? 
The report includes three key fields: campaign_name, total_revenue(before_ _revenue(before_promotion), total_revenue(after_promotion). 
*/
select e.campaign_name,(sum(base_price) * sum(e.qty_sold_before_promo)) total_revenue_bf,
(sum(base_price)* sum(e.qty_sold_after_promo)) total_rvenue_af
from retail_event e
group by 1;

/*
Produce a report that calculates the Incremental Sold Quantity (ISU%) for each category during the Diwali campaign.
 Additionally, provide rankings for the categories based on their ISU%. The report will include three key fields: category, isu%, and rank order
*/
 WITH isu_calculation AS (
SELECT e.category,ROUND((SUM(e.qty_sold_before_promo) * SUM(e.qty_sold_after_promo) / SUM(e.base_price)) * 100, 1) AS isu_per
FROM retail_event e
WHERE e.campaign_name = 'Diwali'
GROUP BY e.category
)
SELECT category,isu_per,DENSE_RANK() OVER (ORDER BY isu_per DESC) AS ranks
FROM isu_calculation;


/*
Create a report featuring the Top 5 products, ranked by Incremental Revenue Percentage (IR%), across all campaigns. 
The report will provide essential information including product name, category, and ir%. 
*/
with incr_calculation as (
Select r.product_name,r.category, ROUND(
        (SUM(r.qty_sold_after_promo) - SUM(r.qty_sold_before_promo)) * SUM(r.base_price) / 
        (NULLIF(SUM(r.base_price) * SUM(r.qty_sold_before_promo), 0)) * 100,1 #null if use avoid  potential division by zero
    ) as in_re
from retail_event r
group by r.product_name,r.category
)
SELECT product_name,category,in_re
FROM (SELECT product_name,category,in_re,dense_rank() over(order by in_re desc) as ranks
FROM incr_calculation
order by 4
limit 5) top_products


















