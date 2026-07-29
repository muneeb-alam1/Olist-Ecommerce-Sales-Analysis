-------------------------- RFM Analysis --------------------------

WITH rfm_base AS (
SELECT c.customer_unique_id,
DATEDIFF((SELECT MAX(order_purchase_timestamp) FROM orders),
MAX(o.order_purchase_timestamp)) AS recency,
COUNT(DISTINCT o.order_id) AS frequency,
ROUND(SUM(op.payment_value), 2) AS monetary
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_payments op ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id),

rfm_scores AS (
SELECT *,
NTILE(5) OVER (ORDER BY recency DESC) AS r_score,
NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
FROM rfm_base),

rfm_segments AS (
SELECT *, CONCAT(r_score, f_score, m_score) AS rfm_code,
CASE
    WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
    WHEN r_score >= 4 AND f_score >= 4 THEN 'Loyal Customers'
    WHEN r_score >= 4 AND f_score <= 3 THEN 'Potential Loyalists'
    WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
    ELSE 'Lost Customers'
 END AS rfm_segment
FROM rfm_scores)

SELECT rfm_segment, COUNT(*) AS total_customers,
ROUND(COUNT(*) / SUM(COUNT(*)) OVER() * 100, 2) AS pct_of_total,
ROUND(AVG(recency), 1) AS avg_recency_days,
ROUND(AVG(frequency), 2) AS avg_orders,
ROUND(AVG(monetary), 2) AS avg_monetary,
ROUND(SUM(monetary), 2) AS total_revenue,
ROUND(SUM(monetary) / SUM(SUM(monetary)) OVER() * 100, 2) AS pct_revenue
FROM rfm_segments
GROUP BY rfm_segment
ORDER BY total_revenue DESC ;









