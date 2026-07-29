-------------------- Payment & Reviews Analysis ---------------------

-- What is the distribution of payment methods used by customers?
SELECT payment_type, COUNT(*) AS transactions,
ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 2) AS share_pct
FROM order_payments op
JOIN orders o ON op.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY payment_type;


-- Which payment methods generate the highest revenue and share ?
SELECT payment_type, ROUND(SUM(op.payment_value), 2) AS revenue,
ROUND(SUM(op.payment_value) /
SUM(SUM(op.payment_value)) OVER() * 100, 2) AS contribution_pct
FROM order_payments op
JOIN orders o ON op.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY op.payment_type
ORDER BY revenue DESC;


-- Revenue by order status (in transit vs completed)
SELECT order_status, ROUND(SUM(p.payment_value), 2) AS revenue
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status IN ('delivered', 'shipped', 'invoiced')
GROUP BY 1;


-- How does installment usage impact order value?
SELECT payment_installments,
COUNT(*) AS total_transactions,
ROUND(AVG(payment_value), 2) AS avg_order_value
FROM order_payments op
JOIN orders o
ON op.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY payment_installments
ORDER BY payment_installments;


-- Which payment methods are growing over time by month MoM?
WITH monthly_payments AS (
SELECT DATE_FORMAT(o.order_purchase_timestamp,'%Y-%m') AS payment_month,
op.payment_type, ROUND(SUM(op.payment_value), 2) AS revenue
FROM orders o
JOIN order_payments op
ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
GROUP BY payment_month, op.payment_type)
SELECT *, ROUND((revenue - LAG(revenue) OVER(PARTITION BY payment_type ORDER BY payment_month)) /
NULLIF(LAG(revenue) OVER(PARTITION BY payment_type ORDER BY payment_month), 0) * 100, 2) AS growth_pct
FROM monthly_payments;


-- What is the distribution of review scores?
SELECT review_score, COUNT(*) AS reviews
FROM order_reviews rv
JOIN orders o
ON rv.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY review_score
ORDER BY review_score DESC;


-- What percentage of reviews are 5 star ratings?
SELECT ROUND(COUNT(CASE WHEN review_score = 5 THEN 1 END) / 
COUNT(*) * 100 , 2) AS five_star_rate_pct
FROM order_reviews orv
JOIN orders o ON orv.order_id = o.order_id
WHERE o.order_status = 'delivered';


-- Which product categories receive the highest ratings?
SELECT COALESCE(pct.product_category_name_english,'Unknown') AS category,
ROUND(AVG(r.review_score),2) AS avg_rating
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
JOIN order_reviews r ON oi.order_id = r.order_id
LEFT JOIN product_category_name_translation pct
ON p.product_category_name = pct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category;