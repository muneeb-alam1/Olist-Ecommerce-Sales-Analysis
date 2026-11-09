# Olist E-Commerce Sales & Customer Analysis End-to-End SQL + Power BI

## 📌 Project Overview
An end-to-end data analyst project covering SQL exploration in MySQL through to an interactive
Power BI dashboard, built on Olist's real Brazilian marketplace data (2016–2018). The project
looks at revenue, delivery performance, seller and product behavior, customer segment, and
geographic trends across the platform.

**Tools used:** MySQL · MySQL Workbench · Power BI
**Skills demonstrated:** Data Cleaning & Transformation · Multi-Table Joins · Aggregations · CTEs
· Window Functions · Date/Time Functions · RFM Customer Segmentation · DAX · Data Modeling · Data Visualization

![MySQL](https://img.shields.io/badge/MySQL-8.0-blue?logo=mysql)
![Tool](https://img.shields.io/badge/Tool-MySQL%20Workbench-orange)
![PowerBI](https://img.shields.io/badge/Power%20BI-Dashboard-yellow?logo=powerbi)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)

---

## Data

This project uses the **Brazilian E-Commerce Public Dataset by Olist** (Kaggle, CC BY-NC-SA 4.0,
2016–2018). Raw CSVs aren't included here download them and place all files in this folder.

**Source:** [Kaggle – Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)

---

## Project Objectives

Olist is a marketplace connecting independent sellers to customers, handling orders, payments,
and delivery in between. This project analyzes that data to answer key business questions about
revenue, delivery, customers, and sellers using SQL analysis across nine related tables, visualized
in an interactive Power BI dashboard.

- Calculate core KPIs: total revenue, order volume, delivery success rate, cancellation rate, AOV, and average review score
- How well is delivery performing, and does delivery speed affect customer satisfaction?
- Identify top-performing and underperforming products, categories, and sellers by revenue, order volume, and customer rating
- Segment customers using RFM (Recency, Frequency, Monetary) analysis to separate loyal, at-risk, and lost customers
- Map sales, order volume, and delivery performance across Brazilian states
- Track month-over-month and year-over-year trends
- Provide data-backed operational and retention recommendations

---

## Database Schema

The dataset consists of **9 related tables**, covering orders, order items, payments, reviews,
customers, sellers, products, product category translations, and geolocation data.

<img width="1016" height="598" alt="image" src="https://github.com/user-attachments/assets/d03dc234-87f0-4e5e-8487-89ac8cfe2d2d" />



---

## Data Cleaning & Transformation

The raw dataset was reviewed and validated in MySQL before analysis to ensure consistency,
correct data types, and reliable joins across all tables.

- Checked key tables for null values across critical columns before starting analysis
- Corrected inconsistent data types on relevant columns
- Confirmed the correct customer level key to use for lifetime value and repeat-purchase analysis
- Documented a data quirk in how order status is recorded, to avoid misinterpreting results
- Standardized which revenue field to use for which type of analysis, and applied it consistently

---

### SQL Techniques Used

**Multi-Table Joins & Aggregations** across orders, payments, reviews, products, and sellers

**CTEs + Window Functions** for growth rates, running totals, and delivery rankings

**`NTILE(5)`** for RFM customer segmentation

**`LAG()`** for month-over-month and year-over-year trend comparisons

**`RANK()` / `DENSE_RANK()` / `ROW_NUMBER()`** for delivery speed and revenue rankings

**Date/Time Functions** for weekday, hourly, and delivery bucket analysis


---

## What I Built

**SQL Layer**
- Executive KPI summary (revenue, orders, AOV, delivery/cancellation rate, review score)
- Order & delivery analysis (weekday/hour patterns, delivery speed vs. satisfaction, late delivery rate)
- Product & category performance (top/bottom by revenue, orders, rating; frequently bought together)
- Customer analysis
- Seller analysis (top-seller concentration, satisfaction, MoM growth)
- Geographic analysis (revenue, orders, AOV by state)
- RFM segmentation Champions, Loyal, Potential Loyalists, At Risk, Lost

**Power BI Layer**
- Connected Power BI directly to the MySQL database (Import mode), loading the SQL-analyzed tables into a data model
  so the dashboard is built from the database tables rather than static CSV exports
- 7-page interactive dashboard connected to MySQL (refreshable from the database)
- DAX measures for revenue, AOV, delivery/cancellation rate, and gap-tolerant MoM growth
- Category Detail **drill-through** with metric toggle and rating-vs-target gauge
- Customer Detail page with one-time vs. repeat breakdown and Top 100 leaderboard
- Seller Analysis scatter chart (orders vs. revenue)
- Geography page with Brazil map and customer-to-seller ratio
- Custom DAX measures stored in a **dedicated Measures Table** for clean model organisation
- RFM Analysis page built on a validated native SQL import

---

## Query Preview

A few highlights from the SQL queries written in this project.


### 1. Does delivery speed impact customer review scores?

```sql
SELECT CASE
WHEN DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) <= 5  THEN '0-5 Days'
WHEN DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) <= 10 THEN '6-10 Days'
WHEN DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp) <= 15 THEN '11-15 Days'
ELSE '15+ Days'
END AS delivery_bucket,
ROUND(AVG(orv.review_score), 2) AS avg_review_score,
COUNT(orv.review_score) AS total_reviews
FROM orders o
JOIN order_reviews orv ON o.order_id = orv.order_id
WHERE o.order_status = 'delivered'
AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_bucket
ORDER BY MIN(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp));
```

**Output**

<img width="340" height="133" alt="image" src="https://github.com/user-attachments/assets/873883db-9007-40c0-a6e2-4b0e6f3a2912" />


---

### 2. Which top 10 sellers generate the highest revenue, and what share of total revenue do they represent?

```sql
WITH ranked AS (
SELECT oi.seller_id, SUM(oi.price) AS revenue
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.seller_id),
rnk AS (SELECT *, ROW_NUMBER() OVER (ORDER BY revenue DESC) AS rn
FROM ranked)
SELECT ROUND(SUM(CASE WHEN rn <= 10 THEN revenue END) * 100.0 /
SUM(revenue), 2) AS top10_seller_contribution_pct
FROM rnk;
```

**Output**

<img width="219" height="79" alt="image" src="https://github.com/user-attachments/assets/e6c68bf3-4b76-4919-b41f-af7e7abb0cfc" />




---

### 3. RFM Segmentation classifying every customer by recency, frequency, and monetary value

```sql
WITH rfm_base AS (
SELECT c.customer_unique_id,
DATEDIFF((SELECT MAX(order_purchase_timestamp) FROM orders),
MAX(o.order_purchase_timestamp)) AS recency,
COUNT(DISTINCT o.order_id) AS frequency,
ROUND(SUM(op.payment_value), 2) AS monetary FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_payments op ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id),

rfm_scores AS (
SELECT *, NTILE(5) OVER (ORDER BY recency DESC, customer_unique_id) AS r_score,
CASE WHEN frequency >= 3 THEN 5
WHEN frequency = 2  THEN 4
ELSE 1 END AS f_score,
NTILE(5) OVER (ORDER BY monetary ASC, customer_unique_id) AS m_score
FROM rfm_base),

rfm_segments AS (
SELECT *, CONCAT(r_score, f_score, m_score) AS rfm_code,
CASE WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
WHEN r_score >= 4 AND f_score >= 4 THEN 'Loyal Customers'
WHEN r_score >= 4 AND f_score = 1 THEN 'Potential Loyalists'
WHEN r_score <= 3 AND f_score >= 4 THEN 'At Risk'
ELSE 'Lost Customers'
END AS rfm_segment FROM rfm_scores)

SELECT rfm_segment,
COUNT(*) AS total_customers,
ROUND(COUNT(*) / SUM(COUNT(*)) OVER () * 100, 2) AS pct_of_total,
ROUND(AVG(recency), 1)  AS avg_recency_days,
ROUND(AVG(frequency), 2) AS avg_orders,
ROUND(AVG(monetary), 2)  AS avg_monetary,
ROUND(SUM(monetary), 2)  AS total_revenue,
ROUND(SUM(monetary) / SUM(SUM(monetary)) OVER () * 100, 2) AS pct_revenue
FROM rfm_segments
GROUP BY rfm_segment
ORDER BY total_revenue DESC;
```

**Output**

<img width="731" height="131" alt="image" src="https://github.com/user-attachments/assets/2a11b161-e1eb-478c-81e7-81aa94633dd6" />



---

## DAX Measures Preview

A few highlights from the DAX measures written in this project.

### 1. Gross Revenue (Product + Shipping)

```dax
Gross Revenue =
CALCULATE(
SUM(order_items[price]) + SUM(order_items[freight_value]),
orders[order_status] = "delivered")
```

### 2. Average Delay Days

```dax
Avg Delay Days = 
CALCULATE(
AVERAGEX(
  orders,
  DATEDIFF(orders[order_estimated_delivery_date], orders[order_delivered_customer_date], DAY)),
  orders[order_status] = "delivered",
  orders[order_delivered_customer_date] > orders[order_estimated_delivery_date])
```

### 3. MoM Delivered Orders (gap tolerant, skips periods with no data)

```dax
Previous Month Delivered Orders = 
VAR CurrentMonth = MAX('DateTable'[StartOfMonth])
VAR PreviousMonthWithData =
MAXX(FILTER(ALL('DateTable'[StartOfMonth]),
        'DateTable'[StartOfMonth] < CurrentMonth &&
         CALCULATE([Delivered Orders]) > 0),
        'DateTable'[StartOfMonth])
RETURN
CALCULATE([Delivered Orders],
'DateTable'[StartOfMonth] = PreviousMonthWithData)
```

---

## Challenges & Solutions


**Challenge 1:** Month-over-month KPI cards kept showing blank or extreme, wrong percentages.
The reason: one early month (November 2016) had zero data, so any measure comparing 
"this month vs. last month" broke whenever it landed on that empty month.

**Solution:** Rebuilt the month-over-month logic to skip empty months and compare against the
nearest month that actually has data, instead of always assuming exactly one month back is valid.

---

**Challenge 2:** RFM segments were wrong: one-time buyers were getting high frequency scores. Since 
97% of customers ordered only once, `NTILE(5)` split these tied values into different buckets arbitrarily,
and the results could change between runs.

**Solution:** Scored frequency directly from order count (1, 2, 3+ orders) and used `NTILE(5)` only for recency
and monetary, with a tie-breaker for reproducible results.

---

## Power BI Dashboard

The SQL findings were then visualized in an interactive Power BI dashboard. The dashboard translates
query results into clear business visuals that a non-technical stakeholder can explore and act on.

### Dashboard Pages

A **7-page interactive Power BI dashboard**, each page designed to answer one core business question:

**Executive Dashboard**: What are the overall sales numbers, revenue trends, and top performing categories?
**Order & Delivery Analysis**: How reliably are we delivering, and does delivery speed affect satisfaction?
**Category Detail**: How is a specific product category performing over time, and how does it compare company wide?
**Geography Analysis**: Which states drive the most revenue and orders, and where is delivery slowest?
**Customer Detail**: Who are our customers, and how much of our revenue comes from repeat buyers?
**Seller Analysis**: Which sellers drive the most revenue, and does seller scale affect customer satisfaction?
**RFM Analysis**: Which customers are our most valuable, and which are at risk of churning?

## 🖼️ Dashboard Preview

#### Page 1: Executive Dashboard

<img width="918" height="490" alt="image" src="https://github.com/user-attachments/assets/28b78f02-9a2e-4058-9495-056a31691e46" />



#### Page 2: Order & Delivery Analysis

<img width="921" height="492" alt="image" src="https://github.com/user-attachments/assets/78a1b14e-1cd7-4f1a-8aa1-3b1cbc47bc4a" />



#### Page 3: Category Detail

<img width="918" height="492" alt="image" src="https://github.com/user-attachments/assets/ec9eb6b1-46ae-4cd9-af4c-dd92656fb45d" />



#### Page 4: Geography Analysis

<img width="919" height="490" alt="image" src="https://github.com/user-attachments/assets/46c37c5f-9bc9-4093-80ee-6fc513ba74bc" />



#### Page 5: Customer Detail

<img width="918" height="490" alt="image" src="https://github.com/user-attachments/assets/4047a4fe-fca3-4581-88c2-16918f041f05" />



#### Page 6: Seller Analysis

<img width="918" height="492" alt="image" src="https://github.com/user-attachments/assets/522eabd6-0b0f-45c3-930f-bfe30bd87c5a" />



#### Page 7: RFM Analysis

<img width="921" height="493" alt="image" src="https://github.com/user-attachments/assets/7d9ef523-83a4-4c1e-bce2-4289434dd80f" />


---

## Key Insights

- **Sales & Orders:** **R$15.4M** from **96.5K** delivered orders (99.4K placed) with an **Average Order Value (AOV) of
  $159.9**, average delivery **12.5 days**, average rating **4.16/5**, delivery success **97%**
  
- **Delivery Performance:** Orders delivered in 0-5 days average **4.44**, but orders taking 16+ days drop to **3.60**.
  Late orders (**8%**) average just **2.57** vs **4.29** on time.

- **Categories:** Health & beauty (**9.3%**), watches & gifts (**8.8%**), and bed & bath (**7.7%**) lead sales. Bed & bath
   has the most orders but a below-average **3.94**.
  
- **Customer Insights:** **97% of customers purchase only once**, while only **3%** return for a second purchase, making
  customer retention the platform's largest growth opportunity.
  
- **Seller Insights:** The top 10 sellers bring in **13%** of sales and the top 10% bring in **67%**. Size doesn't change
  ratings: sellers with 300+ orders average **4.11**, vs **4.18** for sellers under 20 orders. smaller sellers are excluded
  because too few reviews make their averages unreliable.
  
- **Geographic Insights:** Sao Paulo brings in **37%** of sales, and SP, RJ, and MG together bring in **62%**. The average is
  **31** customers per seller, but Bahia and Pernambuco have over **170**
  
- **RFM Analysis:** 97% of customers are one-time buyers: **Lost Customers** (inactive) are 58% of customers and 56% of revenue, and
  **Potential Loyalists** (recent) are 39% and 38.5%. Repeat buyers are rare (**At Risk** 1,600, **Champions** 983, **Loyal** 218)

---

## Business Recommendations

1. **Prioritize customer retention.**  With 97% of customers buying once, even a small
   improvement in repeat rate adds more revenue than acquiring new one-time buyers.
   Test post-purchase offers, follow-up emails and loyalty rewards

2. **Convert "Potential Loyalists" first.** These 36,141 recent one-time buyers (38.5% of
   revenue) averaged 139 days since purchase, so the window is closing. A timely
   second-purchase incentive is the best chance to move them toward repeat behavior.

3. **Maintain fast delivery.** Faster deliveries go with higher ratings (4.44 vs 3.60 for
   15+ days). Prioritize reducing the slowest deliveries, and track late-vs-estimate performance
   alongside delivery time.

4. **Expand seller presence in under served states.** Recruit more sellers in regions with high 
   customer demand but relatively few local sellers to improve marketplace coverage.

5. **Study high-volume sellers.** Sellers with strong volume maintain solid ratings, so
   their practices can inform seller onboarding and support.

6. **Treat "Champions"** as a small but valuable group, not the main revenue engine. Because the
   Champions segment currently contributes a small share of revenue, growing this loyal customer
   base will strengthen long-term business growth.

7. **Exclude incomplete periods from trend analysis.** Early 2016 (very low volume, with an empty
   November 2016) and late 2018 (partial data) should be separated so they don't distort
   growth rates.

---

## How to Use

### SQL Analysis
1. Download the dataset from Kaggle (link in the Data section) and import the 9 CSV files into a MySQL database
2. Open MySQL Workbench and run the files in the `queries/` folder in order
3. Each file covers one analysis area, with comments explaining the business question

### Power BI Dashboard
1. Download the `.pbix` file from the `dashboard/` folder and open it in Power BI Desktop. The data is included in the
   file, so you don't need MySQL to explore it
3. Use the Year and Date Range slicers on each page
4. On the Executive Dashboard, right-click a category in the chart and choose Drill through to open Category Detail, then
   use the metric toggle to switch measures
6. Open the RFM Analysis page to see the customer segments and how much revenue each one brings in

---

## Future Improvements
- Cohort retention analysis by acquisition month
- Seller-level (not just state-level) delivery performance


## Contact
Feel free to reach out if you'd like to connect or discuss this project:
- **LinkedIn:** [linkedin.com/in/muneeb-alam0](https://www.linkedin.com/in/muneeb-alam0/)
- **Email:** muneebalam140@gmail.com

