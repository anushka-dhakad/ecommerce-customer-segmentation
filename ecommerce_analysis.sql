---query 1: customer by segment
SELECT segment, COUNT(*) AS total_customers
FROM customer_segments
GROUP BY segment
ORDER BY total_customers DESC;



-- Query 2: Top 10 highest-spending customers

SELECT customer_id, frequency, monetary, segment
FROM customer_segments
ORDER BY monetary DESC
LIMIT 10;




-- Query 3: Spending by customer segment

SELECT
    segment,
    COUNT(*) AS total_customers,
    ROUND(AVG(monetary), 2) AS avg_spending,
    ROUND(SUM(monetary), 2) AS total_spending
FROM customer_segments
GROUP BY segment
ORDER BY total_spending DESC;



-- Query 4: Monthly revenue analysis

SELECT
    DATE_TRUNC('month', invoice_date)::DATE AS month,
    ROUND(SUM(sales), 2) AS monthly_revenue
FROM transactions
GROUP BY DATE_TRUNC('month', invoice_date)
ORDER BY month;




-- Query 5: Top 10 products by revenue

SELECT
    stock_code,
    MAX(description) AS product_name,
    SUM(quantity) AS total_quantity_sold,
    ROUND(SUM(sales), 2) AS total_revenue
FROM transactions
GROUP BY stock_code
ORDER BY total_revenue DESC
LIMIT 10;




-- Query 6: Revenue by customer segment

SELECT
    c.segment,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    ROUND(SUM(t.sales), 2) AS total_revenue
FROM customer_segments c
JOIN transactions t
    ON c.customer_id = t.customer_id
GROUP BY c.segment
ORDER BY total_revenue DESC;





-- Query 7: Customer Cohort Retention Analysis

WITH customer_cohort AS (
    SELECT
        customer_id,
        MIN(DATE_TRUNC('month', invoice_date)) AS cohort_month
    FROM transactions
    GROUP BY customer_id
),

customer_activity AS (
    SELECT DISTINCT
        customer_id,
        DATE_TRUNC('month', invoice_date) AS activity_month
    FROM transactions
),

cohort_activity AS (
    SELECT
        cc.cohort_month,
        ca.activity_month,
        (
            EXTRACT(YEAR FROM ca.activity_month) * 12
            + EXTRACT(MONTH FROM ca.activity_month)
        ) - (
            EXTRACT(YEAR FROM cc.cohort_month) * 12
            + EXTRACT(MONTH FROM cc.cohort_month)
        ) AS month_number,
        COUNT(DISTINCT ca.customer_id) AS active_customers
    FROM customer_cohort cc
    JOIN customer_activity ca
        ON cc.customer_id = ca.customer_id
    GROUP BY
        cc.cohort_month,
        ca.activity_month
),

cohort_sizes AS (
    SELECT
        cohort_month,
        COUNT(*) AS cohort_customers
    FROM customer_cohort
    GROUP BY cohort_month
)

SELECT
    a.cohort_month::DATE AS cohort_month,
    a.month_number,
    a.active_customers,
    s.cohort_customers,
    ROUND(
        100.0 * a.active_customers / s.cohort_customers,
        2
    ) AS retention_percentage
FROM cohort_activity a
JOIN cohort_sizes s
    ON a.cohort_month = s.cohort_month
ORDER BY
    a.cohort_month,
    a.month_number;



