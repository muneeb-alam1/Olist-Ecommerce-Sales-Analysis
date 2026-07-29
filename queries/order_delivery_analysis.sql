-------------------- Order & Delivery Analysis ---------------------
-- Orders by month
SELECT DATE_FORMAT(order_purchase_timestamp,'%Y-%m') AS month,
MONTHNAME(order_purchase_timestamp) AS Month_Name,
COUNT(DISTINCT order_id) orders
FROM orders
GROUP BY 1,2
ORDER BY 1;


-- Orders by weekday
SELECT
DAYNAME(order_purchase_timestamp) AS day_name,
COUNT(DISTINCT order_id) AS total_orders
FROM orders
GROUP BY DAYOFWEEK(order_purchase_timestamp),
DAYNAME(order_purchase_timestamp)
ORDER BY DAYOFWEEK(order_purchase_timestamp);


-- Order by hour
SELECT DATE_FORMAT(order_purchase_timestamp, '%l %p') AS purchase_hour, 
COUNT(distinct order_id) AS total_orders
FROM orders
GROUP BY purchase_hour
ORDER BY MIN(HOUR(order_purchase_timestamp));


-- Fastest vs Slowest Months
WITH monthly_delivery AS (
SELECT DATE_FORMAT(order_purchase_timestamp,'%Y-%m') AS month,
ROUND(AVG(DATEDIFF(order_delivered_customer_date, order_purchase_timestamp)),1) AS 
avg_delivery_days
FROM orders
WHERE order_status ='delivered'
AND order_delivered_customer_date IS NOT NULL
GROUP BY 1
ORDER BY month asc)
SELECT month, avg_delivery_days, 
RANK() OVER (ORDER BY avg_delivery_days ASC)  AS fastest_rank,
RANK() OVER (ORDER BY avg_delivery_days DESC) AS slowest_rank
FROM monthly_delivery
ORDER BY avg_delivery_days ASC;


-- Which months experienced the highest and lowest order growth rates over time?
WITH monthly_orders AS (
SELECT DATE_FORMAT(order_purchase_timestamp,'%Y-%m') AS order_month,
COUNT(DISTINCT order_id) AS total_orders
FROM orders
GROUP BY order_month)

SELECT order_month, total_orders,
LAG(total_orders) OVER(ORDER BY order_month) AS previous_month_orders,
ROUND(((total_orders - LAG(total_orders) OVER(ORDER BY order_month)) /
NULLIF(LAG(total_orders) OVER(ORDER BY order_month), 0)) * 100, 1) AS growth_rate_pct
FROM monthly_orders
ORDER BY order_month;


-- Which states experience the longest delivery times?
SELECT c.customer_state, ROUND(AVG(DATEDIFF(o.order_delivered_customer_date,
o.order_purchase_timestamp)), 2) AS avg_delivery_days
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;


-- What percentage of orders were delivered late?
SELECT COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 END) 
AS late_orders, COUNT(DISTINCT order_id) AS total_delivered_orders,
ROUND(COUNT(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 END) / 
COUNT(DISTINCT order_id)  * 100, 2) AS late_delivery_pct
FROM orders
WHERE order_status = 'delivered';


-- Does delivery speed impact review scores?
SELECT CASE
WHEN DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) <= 5 THEN '0-5 Days'
WHEN DATEDIFF( o.order_delivered_customer_date, o.order_purchase_timestamp) <= 10 THEN '6-10 Days'
WHEN DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) <= 15 THEN '11-15 Days'
ELSE '15+ Days'
END AS delivery_bucket,
ROUND(AVG(orv.review_score), 2) AS avg_review_score,
COUNT(orv.review_score) AS total_reviews
FROM orders o
JOIN order_reviews orv
ON o.order_id = orv.order_id
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_bucket
ORDER BY MIN(DATEDIFF(o.order_delivered_customer_date,
o.order_purchase_timestamp));


-- Which delivered orders experienced delays and what review scores did customers give?
SELECT o.order_id, DATEDIFF(o.order_delivered_customer_date,
o.order_purchase_timestamp) AS actual_delivery_days,
DATEDIFF(o.order_estimated_delivery_date,
o.order_purchase_timestamp) AS estimated_delivery_days,
DATEDIFF(o.order_delivered_customer_date,
o.order_estimated_delivery_date) AS delay_days, 
r.review_score FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL;