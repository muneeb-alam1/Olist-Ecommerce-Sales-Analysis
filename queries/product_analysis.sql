----------------------- Product Analysis--------------------

-- Which products sell the most units?
SELECT oi.product_id, COUNT(*) AS units_sold
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.product_id 
ORDER BY units_sold DESC 
LIMIT 20;


-- Which products generates highest revenue?
SELECT product_id, ROUND(SUM(oi.price), 2) AS revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY product_id
ORDER BY revenue DESC
LIMIT 20;


-- Which product subcategories generates highest revenue and delivered orders?
SELECT COALESCE(pct.product_category_name_english,'Unknown') AS category,
ROUND(SUM(oi.price),2) AS revenue,
COUNT(DISTINCT o.order_id) AS orders
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation pct
ON p.product_category_name = pct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY pct.product_category_name_english
ORDER BY revenue DESC
LIMIT 10;


-- Which categories are most popular?
SELECT COALESCE(pct.product_category_name_english,'Unknown') AS category,
COUNT(*) AS units_sold
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation pct
ON p.product_category_name = pct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY units_sold DESC;


-- Which categories receive the best reviews?
SELECT COALESCE(pct.product_category_name_english,'Unknown') AS product_category,
ROUND(AVG(orv.review_score),2) AS avg_rating
FROM products p
JOIN order_items oi
ON p.product_id = oi.product_id
JOIN orders o
ON oi.order_id = o.order_id
JOIN order_reviews orv
ON oi.order_id= orv.order_id
LEFT JOIN product_category_name_translation pct
ON p.product_category_name=pct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY pct.product_category_name_english
ORDER BY avg_rating DESC;


-- Which product categories have the lowest customer ratings?
SELECT COALESCE(pct.product_category_name_english,'Unknown') AS category,
ROUND(AVG(orv.review_score),2) AS avg_rating
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
JOIN order_reviews orv
ON oi.order_id= orv.order_id
LEFT JOIN product_category_name_translation pct
ON p.product_category_name=pct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY avg_rating ASC;


-- Which product categories contribute most revenue?
SELECT category, revenue, 
ROUND(revenue / SUM(revenue) OVER() * 100  , 2)  AS revenue_pct FROM
(SELECT COALESCE(pct.product_category_name_english,'Unknown') AS category,
ROUND(SUM(oi.price), 2) AS revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation pct
ON p.product_category_name = pct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY category) AS t
ORDER BY revenue DESC;


-- Which products generate the highest revenue and what percentage of total revenue do they contribute?
WITH product_sales AS (
SELECT product_id, ROUND(SUM(oi.price), 2) AS revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.product_id)
SELECT product_id, revenue, 
ROUND(revenue * 100 / SUM(revenue) OVER(), 2) AS contribution_pct,
DENSE_RANK() OVER(ORDER BY revenue DESC) AS revenue_rank
FROM product_sales
ORDER BY revenue DESC;


-- Which products are frequently purchased together? 
SELECT oi1.product_id AS product_1,
oi2.product_id AS product_2,
COUNT(*) AS times_bought_together
FROM order_items oi1 JOIN order_items oi2
ON  oi1.order_id = oi2.order_id
AND oi1.product_id < oi2.product_id
JOIN orders o ON oi1.order_id = o.order_id
WHERE o.order_status = 'delivered' 
GROUP BY product_1, product_2
HAVING COUNT(*) >= 5
ORDER BY times_bought_together DESC;


-- Running revenue percentage of products
WITH product_revenue AS (
SELECT product_id, ROUND(SUM(oi.price),2) AS revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY product_id)
SELECT product_id, revenue, 
ROUND(SUM(revenue) OVER(ORDER BY revenue DESC) /
SUM(revenue) OVER() * 100, 2) AS cumulative_revenue_pct
FROM product_revenue
ORDER BY revenue DESC;


-- Which categories are growing fastest month-over-month?
WITH monthly_category_sales AS (
SELECT DATE_FORMAT(o.order_purchase_timestamp,'%Y-%m') AS sales_month,
COALESCE(pct.product_category_name_english, 'Unknown') AS category,
ROUND(SUM(oi.price), 2) AS revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation pct
ON p.product_category_name = pct.product_category_name
WHERE order_status = 'delivered'
GROUP BY sales_month, category)
SELECT *, ROUND((revenue - LAG(revenue) OVER( PARTITION BY category ORDER BY sales_month)) /
NULLIF(LAG(revenue) OVER(PARTITION BY category ORDER BY sales_month), 0) * 100, 2) AS growth_pct
FROM monthly_category_sales;


-- Which product catogories have the highest avg order value?
SELECT COALESCE(pct.product_category_name_english,'Unknown') AS category,
ROUND(SUM(oi.price) / COUNT(DISTINCT oi.order_id), 2) AS avg_product_revenue_per_order
FROM order_items oi
JOIN orders o
ON oi.order_id = o.order_id JOIN products p
ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation pct
ON p.product_category_name = pct.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY pct.product_category_name_english
ORDER BY avg_product_revenue_per_order DESC;

