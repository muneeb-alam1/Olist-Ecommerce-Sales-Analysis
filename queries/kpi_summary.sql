----------------------- KPI SUMMARY ---------------------

WITH revenue_cte AS (
SELECT ROUND(SUM(oi.price), 2) AS product_revenue,
ROUND(SUM(oi.freight_value), 2) AS shipping_revenue,
ROUND(SUM(oi.price + oi.freight_value), 2) AS gross_revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'),

orders_cte AS (
SELECT COUNT(DISTINCT order_id) AS total_orders,
SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END) AS delivered_orders,
SUM(CASE WHEN order_status = 'canceled' THEN 1 ELSE 0 END) AS cancelled_orders,
ROUND(SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END) / 
COUNT(DISTINCT order_id) * 100, 2) AS delivery_success_rate,
ROUND(SUM(CASE WHEN order_status = 'canceled' THEN 1 ELSE 0 END) / 
COUNT(DISTINCT order_id) * 100, 2) AS cancellation_rate
FROM orders),

customers_cte AS (
SELECT COUNT(DISTINCT customer_unique_id) AS total_customers
FROM customers),

sellers_cte AS (
SELECT COUNT(DISTINCT seller_id) AS total_sellers
FROM sellers),

aov_cte AS (
SELECT ROUND(SUM(op.payment_value) / 
COUNT(DISTINCT o.order_id), 2) AS aov
FROM order_payments op
JOIN orders o ON op.order_id = o.order_id
WHERE o.order_status = 'delivered'),

review_cte AS (
SELECT ROUND(AVG(orv.review_score), 2) AS avg_score
FROM order_reviews orv JOIN orders o
ON orv.order_id = o.order_id
WHERE o.order_status = 'delivered'),


delivery_time_cte AS (
SELECT ROUND(AVG(DATEDIFF(order_delivered_customer_date, 
order_purchase_timestamp)), 1) AS avg_delivery_days
FROM orders
WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NOT NULL),


orders_per_customer_cte AS (
SELECT ROUND(COUNT(DISTINCT o.order_id) / 
COUNT(DISTINCT c.customer_unique_id), 2) AS avg_orders_per_customer
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered')

SELECT r.product_revenue, r.shipping_revenue,
r.gross_revenue, o.total_orders,
o.delivered_orders, o.cancelled_orders,
o.delivery_success_rate, o.cancellation_rate,
c.total_customers, s.total_sellers,
a.aov, orv.avg_score,
d.avg_delivery_days, opc.avg_orders_per_customer
FROM revenue_cte r
CROSS JOIN orders_cte o
CROSS JOIN customers_cte c
CROSS JOIN sellers_cte s
CROSS JOIN aov_cte a
CROSS JOIN review_cte orv
CROSS JOIN delivery_time_cte d
CROSS JOIN orders_per_customer_cte opc;


-- How has the business performed month-over-month in terms of revenue, orders, customers, and growth rates?
WITH monthly_metrics AS (
SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
ROUND(SUM(op.payment_value), 2) AS total_revenue,
COUNT(DISTINCT o.order_id) AS total_orders,
COUNT(DISTINCT c.customer_unique_id) AS total_customers
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY order_month),
with_lag AS (
SELECT *, LAG(total_revenue) OVER (ORDER BY order_month) AS prev_revenue,
LAG(total_orders)  OVER (ORDER BY order_month) AS prev_orders,
LAG(total_customers) OVER (ORDER BY order_month) AS prev_customers
FROM monthly_metrics)
SELECT order_month, total_revenue, total_orders, total_customers,
ROUND((total_revenue - prev_revenue) / NULLIF(prev_revenue,0) * 100, 2) AS revenue_growth_pct,
ROUND((total_orders - prev_orders) / NULLIF(prev_orders,0) * 100, 2) AS order_growth_pct,
ROUND((total_customers - prev_customers) / NULLIF(prev_customers, 0) * 100, 2) AS customer_growth_pct 
FROM with_lag
ORDER BY order_month;


-- How has the business performed year-over-year in terms of revenue, orders, customers, and growth rates?
WITH yearly_metrics AS (
SELECT YEAR(o.order_purchase_timestamp) AS order_year,
ROUND(SUM(op.payment_value), 2) AS total_revenue,
COUNT(DISTINCT o.order_id) AS total_orders,
COUNT(DISTINCT c.customer_unique_id) AS total_customers
FROM orders o
JOIN order_payments op ON o.order_id = op.order_id
JOIN customers c ON o.customer_id = c.customer_id
WHERE o.order_status = 'delivered'
GROUP BY order_year),
with_lag AS (
SELECT *, LAG(total_revenue) OVER (ORDER BY order_year) AS prev_revenue,
LAG(total_orders) OVER (ORDER BY order_year) AS prev_orders,
LAG(total_customers) OVER (ORDER BY order_year) AS prev_customers
FROM yearly_metrics)
SELECT order_year, total_revenue, total_orders, total_customers,
ROUND((total_revenue - prev_revenue) / NULLIF(prev_revenue,0) * 100, 2) AS revenue_growth_pct,
ROUND((total_orders - prev_orders) / NULLIF(prev_orders,0) * 100, 2) AS order_growth_pct,
ROUND((total_customers - prev_customers) / NULLIF(prev_customers,0) * 100, 2) AS customer_growth_pct
FROM with_lag
ORDER BY order_year;


-- One time Vs Repeat Customers
WITH customer_orders AS (
SELECT c.customer_unique_id,
COUNT(DISTINCT o.order_id) AS order_count FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id)
SELECT CASE WHEN order_count = 1 THEN 'One time'
ELSE 'Repeat' END AS customer_type,
COUNT(*) AS customers FROM customer_orders
GROUP BY customer_type;

