-------------------------------- Customer Analysis ---------------------------------

-- Which states have the highest number of customers?
SELECT customer_state AS state,
COUNT(DISTINCT customer_unique_id) AS customers
FROM customers
GROUP BY state
ORDER BY customers DESC;


-- Which states generate the highest revenue and orders?
SELECT c.customer_state,
ROUND(SUM(op.payment_value), 2) AS revenue,
COUNT(DISTINCT o.order_id) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_payments op
ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY revenue DESC;


-- What is the average customer lifetime value (CLV)?
SELECT ROUND(SUM(op.payment_value) /
COUNT(DISTINCT c.customer_unique_id), 2) AS customer_lifetime_value
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
JOIN order_payments op
ON o.order_id = op.order_id
WHERE o.order_status = 'delivered';


-- Who are the highest lifetime value (CLV), orders, quantity and avg spend of customers?
WITH item_counts AS (
SELECT order_id, COUNT(order_item_id) AS items_purchased
FROM order_items
GROUP BY order_id),
payment_totals AS (
SELECT order_id, SUM(payment_value) AS order_payment_value
FROM order_payments
GROUP BY order_id)
SELECT c.customer_unique_id,
COUNT(DISTINCT o.order_id) AS total_orders,
SUM(ic.items_purchased) AS items_purchased,
ROUND(SUM(pt.order_payment_value), 2) AS lifetime_value,
ROUND(AVG(pt.order_payment_value), 2) AS avg_spend_per_order
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN item_counts ic ON o.order_id = ic.order_id
JOIN payment_totals pt ON o.order_id = pt.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY lifetime_value DESC
LIMIT 20;


-- What percentage of customers are repeat customers?
WITH customer_orders AS (
SELECT c.customer_unique_id,
COUNT(DISTINCT o.order_id) AS total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id)
SELECT COUNT(CASE WHEN total_orders > 1 THEN 1 END) AS repeat_customers,
ROUND(COUNT(CASE WHEN total_orders > 1 THEN 1 END) / 
COUNT(*) * 100 ,  2) AS repeat_customer_pct
FROM customer_orders;


-- Which customers have become inactive and may be at risk of churn?
SELECT c.customer_unique_id, MAX(o.order_purchase_timestamp) AS last_purchase_date,
DATEDIFF(MAX(o.order_purchase_timestamp),
MIN(o.order_purchase_timestamp)) AS customer_lifespan_days,
COUNT(DISTINCT o.order_id) AS total_orders
FROM customers c JOIN orders o
ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
HAVING DATEDIFF((SELECT MAX(order_purchase_timestamp) FROM orders),
MAX(o.order_purchase_timestamp)) > 60
ORDER BY last_purchase_date ASC;


-- Which states have the highest average customer value?
WITH customer_value AS (
SELECT c.customer_state,
c.customer_unique_id,
SUM(op.payment_value) AS customer_revenue
FROM customers c JOIN orders o
ON c.customer_id = o.customer_id
JOIN order_payments op ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state,
c.customer_unique_id)
SELECT customer_state,
ROUND(AVG(customer_revenue),2) AS avg_customer_value
FROM customer_value
GROUP BY customer_state
ORDER BY avg_customer_value DESC;

