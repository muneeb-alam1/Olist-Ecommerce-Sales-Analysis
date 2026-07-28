# 🛒 Olist E-Commerce Sales & Customer Analysis End-to-End SQL + Power BI


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

## 🎯 Project Objectives

Olist is a marketplace connecting independent sellers to customers, handling orders, payments,
and delivery in between. This project analyzes that data to answer key business questions about
revenue, delivery, customers, and sellers using SQL analysis across nine related tables, visualized
in an interactive Power BI dashboard.

- Calculate core KPIs: total revenue, order volume, delivery success rate, cancellation rate, AOV, and average review score
- How well is delivery performing, and does delivery speed affect customer satisfaction?
- Identify top-performing and underperforming products, categories, and sellers by revenue, order volume, and customer rating
- Segment customers using RFM (Recency, Frequency, Monetary) analysis to separate loyal, at-risk, and lost customers
- Map revenue, order volume, and delivery performance across Brazilian states
- How has the business trended month-over-month and year-over-year?
- Provide data-backed operational and retention recommendations

---

## 🗄️ Database Schema

The dataset consists of **9 related tables**, covering orders, order items, payments, reviews,
customers, sellers, products, product category translations, and geolocation data.

<img width="1018" height="601" alt="image" src="https://github.com/user-attachments/assets/abb0ba7f-daed-411a-a3b5-2d31c7f8e4f4" />



---

## 🧹 Data Cleaning & Transformation

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

## 🛠️ What I Built

**SQL Layer**
- Executive KPI summary (revenue, orders, AOV, delivery/cancellation rate, review score)
- Order & delivery analysis (weekday/hour patterns, delivery speed vs. satisfaction, late delivery rate)
- Product & category performance (top/bottom by revenue, orders, rating; frequently bought together)
- Customer analysis (CLV, repeat rate, churn detection, state-level value)
- Seller analysis (top-seller concentration, satisfaction, MoM growth)
- Geographic analysis (revenue, orders, AOV by state)
- RFM segmentation via `NTILE(5)` Champions, Loyal, Potential Loyalists, At Risk, Lost

**Power BI Layer**
- Connected Power BI directly to the MySQL database, bringing the SQL-analyzed tables into a live
  model so the dashboard visualizes real, connected data rather than static exports
- 7-page interactive dashboard on a live MySQL connection
- Full star-schema model with a dedicated Date table for time intelligence
- DAX measures for revenue, AOV, delivery/cancellation rate, and gap-tolerant MoM growth
- Category Detail **drill-through** with metric toggle and rating-vs-target gauge
- Customer Detail page with one-time vs. repeat breakdown and Top 100 leaderboard
- Seller Analysis scatter chart (volume vs. rating)
- Geography page with Brazil map and customer-to-seller ratio
- Custom DAX measures stored in a **dedicated Measures Table** for clean model organisation
- RFM Analysis page built on a validated native SQL import

---

## 🔍 Query Preview

A few highlights from the SQL queries written in this project.


---

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

<img width="342" height="132" alt="image" src="https://github.com/user-attachments/assets/26782e44-44e3-4c5c-8685-29350cfa0288" />


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

<img width="220" height="78" alt="image" src="https://github.com/user-attachments/assets/b0c09baa-1547-47a0-bcec-aa8fadcc791f" />


---

### 3. RFM Segmentation classifying every customer by recency, frequency, and monetary value

```sql
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
ORDER BY total_revenue DESC;
```

**Output**

<img width="747" height="138" alt="image" src="https://github.com/user-attachments/assets/53e298f7-7191-4122-a3a5-60588c5b8d7f" />


---

## 🧮 DAX Measures Preview

A few highlights from the DAX measures written in this project.

### 1. Gross Revenue (Product + Shipping)

```dax
Total Revenue =
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

## ⚠️ Challenges & Solutions


**Challenge 1:** Month-over-month KPI cards kept showing blank or extreme, wrong percentages.
The reason: one early month (November 2016) had zero data, so any measure comparing 
"this month vs. last month" broke whenever it landed on that empty month.

**Solution:** Rebuilt the month-over-month logic to skip empty months and compare against the
nearest month that actually has data, instead of always assuming exactly one month back is valid.

---

**Challenge 2:** RFM segment counts in Power BI didn't match the SQL results.

**Solution:** This happened because **DAX `RANKX`** handles tied values differently than SQL's **`NTILE`**.
To ensure accurate segmentation, I performed the RFM analysis in SQL and imported the results directly into Power BI.

---

## 📊 Power BI Dashboard

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

### Dashboard Preview

#### Page 1: Executive Dashboard

<img width="1038" height="556" alt="image" src="https://github.com/user-attachments/assets/940e7273-db2e-48c6-a730-ae9ca2ddec0f" />


#### Page 2: Order & Delivery Analysis

<img width="1036" height="555" alt="image" src="https://github.com/user-attachments/assets/5c1c1150-2b3a-44b7-bbc2-9d59920dd530" />


#### Page 3: Category Detail

<img width="1041" height="559" alt="image" src="https://github.com/user-attachments/assets/7f83b3cb-d24b-4fb1-835d-fdf3c8c4e1be" />


#### Page 4: Geography Analysis

<img width="1041" height="559" alt="image" src="https://github.com/user-attachments/assets/a268aac4-d541-47e8-811b-c84771f5ee09" />


#### Page 5: Customer Detail

<img width="1037" height="555" alt="image" src="https://github.com/user-attachments/assets/90e5e641-3629-4dc8-b0e1-7a4c07ba277a" />


#### Page 6: Seller Analysis

<img width="1042" height="560" alt="image" src="https://github.com/user-attachments/assets/5ee88303-df4c-4d0a-91b3-b0419d512dfd" />


#### Page 7: RFM Analysis

<img width="1038" height="558" alt="image" src="https://github.com/user-attachments/assets/82b406aa-49e5-4647-9eb5-6dc49b5142f1" />


---

## 📊 Key Insights

- **Revenue & Orders:** Generated **$15.4M** from **99.4K orders**, with an **Average Order Value (AOV) of $159.9**,
  **12.5-day** average delivery time, **4.16/5** average customer rating, and a **97%** delivery success rate.
  
- **Delivery Performance:** Faster deliveries consistently result in higher customer satisfaction 0-5 day deliveries
   average 4.44★; 15+ day deliveries drop to 3.60★
  
- **Customer Insights:** **97% of customers purchase only once**, while only **3%** return for a second purchase,
   making customer retention the platform's largest growth opportunity.
  
- **Seller Insights:** High-volume sellers consistently maintain **4.0–4.3★** ratings, while small sellers show
   more inconsistent customer ratings. The **Top 10 sellers** generate approximately **13%** of marketplace
   revenue,indicating healthy revenue distribution.
  
- **Geographic Insights**, Customers and revenue are heavily concentrated in **São Paulo** and a few major states.
   The platform averages **31 customers per seller**, with several regions showing high customer demand but relatively
   few sellers, highlighting expansion opportunities.
  
- **RFM Analysis:** **At Risk** customers account for **40% of total revenue**, whereas **Champions** contribute only
   **2.38%**, making retention of at-risk customers a critical business priority.

---

## 💡 Business Recommendations

1. **Prioritize customer retention.** Since **97%** of customers purchase only once, improving 
   repeat purchases will have a bigger impact on revenue than acquiring more one time buyers.

2. **Focus on the "At Risk" customer segment.** This group already generates **40% of total revenue**. 
   Losing them would hurt the business more than losing any other segment. Targeted win-back 
   campaigns, loyalty rewards, and personalized offers can help reduce churn.

3. **Maintain fast delivery.** The data shows faster deliveries consistently receive higher 
   customer ratings, making delivery speed a key driver of customer satisfaction and retention.

4. **Expand seller presence in under served states.** Recruit more sellers in regions with high 
   customer demand but relatively few local sellers to improve marketplace coverage.

5. **Learn from top-performing sellers.** High-volume sellers maintain strong ratings, so their 
   best practices can be used to improve seller onboarding and support.

6. **Treat "Champions"** as a small but valuable group, not the main revenue engine. Because the
   Champions segment currently contributes a small share of revenue, growing this loyal customer
   base will strengthen long-term business growth.

7. **Exclude early launch data from future analysis.** The low order volume during the platform's 
   early months is not representative and should be separated from ongoing performance analysis.

---

## 🚀 How to Use

### SQL Analysis
1. Clone or download this repository
2. Import the Olist dataset from the `data/` folder into MySQL
3. Open MySQL Workbench and run the files in the `queries/` folder in order
4. Each file is organized by analysis section and includes inline comments explaining the business
   question

### Power BI Dashboard
1. Download the `.pbix` file from the `dashboard/` folder
2. Open in Power BI Desktop and connect it to your own MySQL instance of the Olist database
3. Use the Year and Date Range slicers on each page, the metric-selector toggle on the Category
   Detail page, and the drill-through from the Executive Dashboard's category chart to explore
   findings interactively
4. Visit the RFM Analysis page to explore the customer segment breakdown and see which segments
   drive the most revenue

---

## 📌 Future Improvements
- Cohort retention analysis by acquisition month
- Seller-level (not just state-level) delivery performance
- Publish to Power BI Service for a shareable live link
