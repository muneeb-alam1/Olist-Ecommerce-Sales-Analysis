----------------------------- Geographic Analysis ---------------------------

-- Which states have the highest number of orders?
SELECT customer_state AS state,
COUNT(DISTINCT o.order_id) AS orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY state
ORDER BY orders DESC;


-- Which states have the highest number of unique customers?
SELECT customer_state AS state,
COUNT(DISTINCT c.customer_unique_id) AS customers
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY state
ORDER BY customers DESC;


-- Which states have the most sellers?
SELECT seller_state AS state,
COUNT(DISTINCT seller_id) AS sellers
FROM sellers
GROUP BY state
ORDER BY sellers DESC;


-- Which states have the highest average review score?
SELECT c.customer_state AS state,
ROUND(AVG(r.review_score), 2) AS avg_rating
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = "delivered"
GROUP BY state
ORDER BY avg_rating DESC;


-- Which states generate the highest revenue and what percentage of total revenue do they contribute?
SELECT c.customer_state,
ROUND(SUM(op.payment_value), 2) AS revenue,
ROUND(SUM(op.payment_value) /
SUM(SUM(op.payment_value)) OVER() * 100, 2) AS revenue_contribution_pct
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
JOIN order_payments op
ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY revenue DESC;


-- Which states have the highest Average Order Value (AOV)?
SELECT c.customer_state,
ROUND(SUM(op.payment_value) /
COUNT(DISTINCT o.order_id), 2) AS avg_order_value
FROM customers c JOIN orders o
ON c.customer_id = o.customer_id
JOIN order_payments op
ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
HAVING COUNT(DISTINCT o.order_id) >= 100
ORDER BY avg_order_value DESC;

