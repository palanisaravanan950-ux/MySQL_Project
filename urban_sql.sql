USE urban;
SHOW TABLES;
DESCRIBE customers;
DESCRIBE service_connections;
DESCRIBE meter_readings;
DESCRIBE work_orders;
ALTER TABLE work_orders
RENAME COLUMN `ï»¿work_order_id` TO work_order_id;


SELECT 'customers' AS table_name, COUNT(1) AS row_count FROM urban.customers
UNION ALL
SELECT 'service_connections', COUNT(1) FROM urban.service_connections
UNION ALL
SELECT 'meter_readings', COUNT(1) FROM urban.meter_readings
UNION ALL
SELECT 'work_orders', COUNT(1) FROM urban.work_orders;

-- Inspect a few rows from each table.
SELECT * FROM customers ORDER BY customer_id LIMIT 10;
SELECT * FROM service_connections ORDER BY connection_id LIMIT 10;
SELECT * FROM meter_readings ORDER BY reading_id LIMIT 10;
SELECT * FROM work_orders ORDER BY work_order_id LIMIT 10;

/* PART 1 — BASIC SELECT, FILTERS, SORTING, AND DISTINCT */
-- Active customer accounts.
SELECT customer_id, customer_name, customer_type, district
FROM customers
WHERE account_status = 'Active'
ORDER BY district, customer_name;

-- Select only small-business accounts.
SELECT customer_id, customer_name, email, phone
FROM customers
WHERE customer_type = 'Small Business'
ORDER BY customer_name;

-- Multiple conditions with AND / OR / NOT.
SELECT customer_id, customer_name, district, account_status
FROM customers
WHERE account_status = 'Active'
  AND (district = 'Riverside' OR district = 'Lakeside')
ORDER BY district;

SHOW COLUMNS FROM urban.service_connections;
SELECT connections_id, connection_type, connection_status
FROM service_connections
WHERE NOT connection_status = 'Active'
ORDER BY connection_status, connections_id;

-- IN, BETWEEN, LIKE, and comparison operators.
SELECT connections_id, connection_type
FROM service_connections
WHERE connection_type IN ('Standard', 'Shared Meter');

SELECT reading_id, connections_id, consumption_m3
FROM meter_readings
WHERE consumption_m3 BETWEEN 20 AND 40
ORDER BY consumption_m3 DESC;

SELECT customer_id, customer_name, district
FROM customers
WHERE customer_name LIKE 'A%'
ORDER BY customer_name;

SELECT work_order_id, issue_type, priority, work_order_status
FROM work_orders
WHERE priority IN ('High', 'Emergency')
  AND work_order_status <> 'Resolved'
ORDER BY priority, reported_date;

-- NULL handling and unique values.
SELECT DISTINCT district FROM customers ORDER BY district;
SELECT DISTINCT connection_type FROM service_connections ORDER BY connection_type;
SELECT work_order_id, resolved_date FROM work_orders WHERE resolved_date IS NULL LIMIT 20;
SELECT work_order_id, resolved_date FROM work_orders WHERE resolved_date IS NOT NULL LIMIT 20;

-- Accounts by status and district.
SELECT account_status, COUNT(*) AS account_count
FROM customers
GROUP BY account_status
ORDER BY account_count DESC;

SELECT district, COUNT(*) AS customer_count
FROM customers
GROUP BY district
ORDER BY customer_count DESC, district;

-- WHERE filters rows before grouping; HAVING filters groups after aggregation.
SELECT district, COUNT(*) AS active_customers
FROM customers
WHERE account_status = 'Active'
GROUP BY district
HAVING COUNT(*) >= 50
ORDER BY active_customers DESC;

-- Consumption summaries.
SELECT COUNT(*) AS readings,
       SUM(consumption_m3) AS total_consumption_m3,
       ROUND(AVG(consumption_m3), 2) AS average_m3,
       MIN(consumption_m3) AS minimum_m3,
       MAX(consumption_m3) AS maximum_m3
FROM meter_readings;

SELECT reading_method,
       COUNT(*) AS reading_count,
       ROUND(AVG(consumption_m3), 2) AS average_consumption_m3,
       SUM(consumption_m3) AS total_consumption_m3
FROM meter_readings
GROUP BY reading_method
ORDER BY average_consumption_m3 DESC;

-- Work orders by issue, priority, and status.
SELECT issue_type, COUNT(*) AS work_order_count
FROM work_orders
GROUP BY issue_type
HAVING COUNT(*) > 1
ORDER BY work_order_count DESC;

SELECT priority, work_order_status, COUNT(*) AS total
FROM work_orders
GROUP BY priority, work_order_status
ORDER BY priority, total DESC;



-- INNER JOIN: customers and service connections.
SELECT c.customer_id, c.customer_name, c.district,
       sc.connections_id, sc.connection_type, sc.connection_status
FROM customers AS c
INNER JOIN service_connections AS sc
    ON sc.customer_id = c.customer_id
ORDER BY c.customer_id
LIMIT 100;

-- LEFT JOIN: retain every customer, including customers without a matched connection.
SELECT c.customer_id, c.customer_name,
       COUNT(sc.connections_id) AS connection_count
FROM customers AS c
LEFT JOIN service_connections AS sc
    ON sc.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY connection_count, c.customer_id;

-- Meter usage with customer and district details.
SELECT c.customer_name, c.district, sc.connections_id,
       mr.reading_date, mr.consumption_m3, mr.reading_method
FROM customers AS c
JOIN service_connections AS sc ON sc.customer_id = c.customer_id
JOIN meter_readings AS mr ON mr.connection_id = sc.connections_id
ORDER BY mr.consumption_m3 DESC
LIMIT 50;

-- Work-order report across three related tables.
SELECT wo.work_order_id, wo.issue_type, wo.priority,
       wo.work_order_status, wo.reported_date,
       sc.connections_id, c.customer_name, c.district
FROM work_orders AS wo
JOIN service_connections AS sc ON sc.connections_id = wo.connection_id
JOIN customers AS c ON c.customer_id = sc.customer_id
ORDER BY wo.reported_date DESC
LIMIT 100;

-- Connections with no matching reading (LEFT JOIN ... IS NULL).
SELECT sc.connections_id, sc.customer_id, sc.connection_status
FROM service_connections AS sc
LEFT JOIN meter_readings AS mr ON mr.connection_id = sc.connections_id
WHERE mr.reading_id IS NULL;

-- Customers with no open work orders (NOT EXISTS).
SELECT c.customer_id, c.customer_name, c.district
FROM customers AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM service_connections AS sc
    JOIN work_orders AS wo ON wo.connection_id = sc.connections_id
    WHERE sc.customer_id = c.customer_id
      AND wo.work_order_status IN ('Open', 'Assigned', 'In Progress')
)
ORDER BY c.customer_name
LIMIT 100;

-- Self join: customers in the same district, each pair shown once.
SELECT a.district, a.customer_name AS customer_1, b.customer_name AS customer_2
FROM customers AS a
JOIN customers AS b
  ON a.district = b.district
 AND a.customer_id < b.customer_id
ORDER BY a.district, customer_1
LIMIT 100;

SELECT customer_name,
       UPPER(customer_name) AS upper_name,
       LOWER(email) AS lower_email,
       CHAR_LENGTH(customer_name) AS name_length,
       CONCAT(customer_id, ' - ', customer_name) AS customer_label
FROM customers
LIMIT 20;

SELECT customer_name,
       SUBSTRING_INDEX(customer_name, ' ', 1) AS first_name,
       SUBSTRING_INDEX(customer_name, ' ', -1) AS last_name,
       TRIM(email) AS trimmed_email
FROM customers
LIMIT 20;

SELECT reading_date,
       DATE_FORMAT(reading_date, '%Y-%m') AS reading_month_key,
       YEAR(reading_date) AS reading_year,
       MONTHNAME(reading_date) AS reading_month,
       DAYNAME(reading_date) AS reading_weekday
FROM urban.meter_readings
ORDER BY reading_date
LIMIT 30;

SELECT reported_date,
       DATE_ADD(reported_date, INTERVAL 7 DAY) AS one_week_later,
       DATEDIFF(CURDATE(), reported_date) AS days_since_report
FROM work_orders
ORDER BY reported_date DESC
LIMIT 30;

SELECT consumption_m3,
       ABS(consumption_m3) AS absolute_value,
       ROUND(consumption_m3 / 3, 2) AS rounded_third,
       CEILING(consumption_m3 / 3) AS rounded_up,
       FLOOR(consumption_m3 / 3) AS rounded_down,
       MOD(consumption_m3, 5) AS remainder_by_five
FROM meter_readings
LIMIT 20;

-- CASE classifies readings by consumption volume.
SELECT reading_id, connection_id, consumption_m3,
       CASE
         WHEN consumption_m3 >= 50 THEN 'High use'
         WHEN consumption_m3 >= 25 THEN 'Medium use'
         ELSE 'Low use'
       END AS usage_band
FROM meter_readings
ORDER BY consumption_m3 DESC
LIMIT 50;

-- COALESCE and IFNULL replace missing values for display.
SELECT work_order_id,
       COALESCE(resolved_date, 'Not resolved') AS resolution_display,
       IFNULL(resolved_date, 'Not resolved') AS resolution_alternative
FROM work_orders
LIMIT 30;

-- Conditional aggregation: work-order statuses as separate counts.
SELECT priority,
       SUM(CASE WHEN work_order_status = 'Open' THEN 1 ELSE 0 END) AS open_count,
       SUM(CASE WHEN work_order_status = 'Assigned' THEN 1 ELSE 0 END) AS assigned_count,
       SUM(CASE WHEN work_order_status = 'In Progress' THEN 1 ELSE 0 END) AS in_progress_count,
       SUM(CASE WHEN work_order_status = 'Resolved' THEN 1 ELSE 0 END) AS resolved_count
FROM work_orders
GROUP BY priority
ORDER BY priority;

-- Find duplicate emails after trimming and ignoring case.
SELECT LOWER(TRIM(email)) AS normalized_email, COUNT(*) AS copies
FROM customers
WHERE email IS NOT NULL
GROUP BY LOWER(TRIM(email))
HAVING COUNT(*) > 1;

-- Find duplicate meter IDs.
SELECT meter_id, COUNT(*) AS copies
FROM service_connections
GROUP BY meter_id
HAVING COUNT(*) > 1;

-- Check for readings whose values do not reconcile.
SELECT reading_id, previous_reading_m3, current_reading_m3, consumption_m3
FROM meter_readings
WHERE current_reading_m3 - previous_reading_m3 <> consumption_m3;

-- Check for connections with unknown customer IDs.
SELECT sc.connections_id, sc.customer_id
FROM service_connections AS sc
LEFT JOIN customers AS c ON c.customer_id = sc.customer_id
WHERE c.customer_id IS NULL;

-- Check for work orders with unknown connection IDs.
SELECT wo.work_order_id, wo.connection_id
FROM work_orders AS wo
LEFT JOIN service_connections AS sc ON sc.connections_id = wo.connection_id
WHERE sc.connections_id IS NULL;

-- ROW_NUMBER can identify duplicate email rows without deleting anything.
SELECT customer_id, customer_name, email,
       ROW_NUMBER() OVER (PARTITION BY LOWER(TRIM(email)) ORDER BY customer_id) AS duplicate_number
FROM customers
WHERE email IS NOT NULL;

-- Rank connections by consumption.
SELECT connection_id,
       consumption_m3,
       ROW_NUMBER() OVER (
           ORDER BY consumption_m3 DESC, connection_id
       ) AS row_number_rank,
       RANK() OVER (
           ORDER BY consumption_m3 DESC
       ) AS consumption_rank,
       DENSE_RANK() OVER (
           ORDER BY consumption_m3 DESC
       ) AS dense_position
FROM urban.meter_readings
ORDER BY consumption_rank
LIMIT 50;

-- Rank readings within each district.
WITH district_usage AS (
    SELECT c.district, sc.connections_id, mr.consumption_m3
    FROM customers AS c
    JOIN service_connections AS sc ON sc.customer_id = c.customer_id
    JOIN meter_readings AS mr ON mr.connection_id = sc.connections_id
), ranked_usage AS (
    SELECT district, connections_id, consumption_m3,
           ROW_NUMBER() OVER (PARTITION BY district ORDER BY consumption_m3 DESC) AS district_rank
    FROM district_usage
)
SELECT district, connections_id, consumption_m3, district_rank
FROM ranked_usage
WHERE district_rank <= 5
ORDER BY district, district_rank;

-- Compare each connection reading with the overall average using a window.
SELECT connection_id, consumption_m3,
       ROUND(AVG(consumption_m3) OVER (), 2) AS overall_average,
       consumption_m3 - AVG(consumption_m3) OVER () AS difference_from_average
FROM meter_readings
ORDER BY difference_from_average DESC
LIMIT 50;

-- LAG and LEAD across a connection's readings, ordered by date.
SELECT connection_id, reading_date, consumption_m3,
       LAG(consumption_m3) OVER (PARTITION BY connection_id ORDER BY reading_date) AS previous_reading_use,
       LEAD(consumption_m3) OVER (PARTITION BY connection_id ORDER BY reading_date) AS next_reading_use
FROM meter_readings
ORDER BY connection_id, reading_date
LIMIT 50;

-- District running total of consumption.
WITH usage_rows AS (
    SELECT c.district, mr.reading_date, mr.reading_id, mr.consumption_m3
    FROM customers AS c
    JOIN service_connections AS sc ON sc.customer_id = c.customer_id
    JOIN meter_readings AS mr ON mr.connection_id = sc.connections_id
)
SELECT district, reading_date, reading_id, consumption_m3,
       SUM(consumption_m3) OVER (
           PARTITION BY district
           ORDER BY reading_date, reading_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
       ) AS district_running_consumption
FROM usage_rows
ORDER BY district, reading_date
LIMIT 100;

-- Connection status overview.
SELECT connection_status, COUNT(*) AS connections
FROM service_connections
GROUP BY connection_status
ORDER BY connections DESC;

-- Active connections and customers by district.
SELECT c.district,
       COUNT(DISTINCT c.customer_id) AS customers,
       SUM(sc.connections_status = 'Active') AS active_connections,
       COUNT(sc.connections_id) AS total_connections
FROM customers AS c
JOIN service_connections AS sc ON sc.customer_id = c.customer_id
GROUP BY c.district
ORDER BY active_connections DESC;

-- Average and total water consumption by district.
SELECT c.district,
       COUNT(mr.reading_id) AS readings,
       ROUND(AVG(mr.consumption_m3), 2) AS avg_consumption_m3,
       SUM(mr.consumption_m3) AS total_consumption_m3
FROM customers AS c
JOIN service_connections AS sc ON sc.customer_id = c.customer_id
JOIN meter_readings AS mr ON mr.connection_id = sc.connections_id
GROUP BY c.district
ORDER BY total_consumption_m3 DESC;

-- Open work orders by district and percentage of all work orders.
SELECT c.district,
       COUNT(*) AS open_orders,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM work_orders), 2) AS percent_of_all_orders
FROM customers AS c
JOIN service_connections AS sc ON sc.customer_id = c.customer_id
JOIN work_orders AS wo ON wo.connection_id = sc.connections_id
WHERE wo.work_order_status IN ('Open', 'Assigned', 'In Progress')
GROUP BY c.district
ORDER BY open_orders DESC;

-- Resolution time in days for resolved work orders.
SELECT wo.work_order_id, wo.issue_type, wo.priority,
       DATEDIFF(wo.resolved_date, wo.reported_date) AS resolution_days
FROM work_orders AS wo
WHERE wo.work_order_status = 'Resolved'
  AND wo.resolved_date IS NOT NULL
ORDER BY resolution_days DESC
LIMIT 50;

-- Issue type with the longest average resolution time.
SELECT issue_type,
       ROUND(AVG(DATEDIFF(resolved_date, reported_date)), 2) AS avg_resolution_days,
       COUNT(*) AS resolved_orders
FROM work_orders
WHERE work_order_status = 'Resolved'
  AND resolved_date IS NOT NULL
GROUP BY issue_type
HAVING COUNT(*) >= 1
ORDER BY avg_resolution_days DESC;

-- High-use connections with customer context.
SELECT c.customer_name, c.district, sc.connections_id,
       mr.consumption_m3, mr.reading_date
FROM meter_readings AS mr
JOIN service_connections AS sc ON sc.connections_id = mr.connection_id
JOIN customers AS c ON c.customer_id = sc.customer_id
WHERE mr.consumption_m3 > (SELECT AVG(consumption_m3) FROM meter_readings)
ORDER BY mr.consumption_m3 DESC
LIMIT 100;

-- CTE: prepare unresolved work orders, then summarize by district.
WITH unresolved AS (
    SELECT connection_id, priority, work_order_status
    FROM work_orders
    WHERE work_order_status IN ('Open', 'Assigned', 'In Progress')
)
SELECT c.district, COUNT(*) AS unresolved_orders,
       SUM(u.priority = 'Emergency') AS emergency_orders
FROM unresolved AS u
JOIN service_connections AS sc ON sc.connections_id = u.connection_id
JOIN customers AS c ON c.customer_id = sc.customer_id
GROUP BY c.district
ORDER BY unresolved_orders DESC;

-- Q1: Show customers with active accounts in each district.
SELECT district, customer_id, customer_name
FROM customers
WHERE account_status = 'Active'
ORDER BY district, customer_name;

-- Q2: Which reading methods have average consumption above 25 m3?
SELECT reading_method, ROUND(AVG(consumption_m3), 2) AS average_m3
FROM meter_readings
GROUP BY reading_method
HAVING AVG(consumption_m3) > 25
ORDER BY average_m3 DESC;

-- Q3: Find the top three consumption readings per district.
WITH ranked AS (
    SELECT c.district, sc.connections_id, mr.consumption_m3,
           ROW_NUMBER() OVER (PARTITION BY c.district ORDER BY mr.consumption_m3 DESC) AS rn
    FROM customers AS c
    JOIN service_connections AS sc ON sc.customer_id = c.customer_id
    JOIN meter_readings AS mr ON mr.connection_id = sc.connections_id
)
SELECT district, connections_id, consumption_m3, rn
FROM ranked
WHERE rn <= 3
ORDER BY district, rn;

-- Q4: Find customers who have at least one emergency work order.
SELECT DISTINCT c.customer_id, c.customer_name, c.district
FROM customers AS c
JOIN service_connections AS sc ON sc.customer_id = c.customer_id
JOIN work_orders AS wo ON wo.connection_id = sc.connections_id
WHERE wo.priority = 'Emergency'
ORDER BY c.district, c.customer_name;

-- Q5: Find connections with no work orders.
SELECT sc.connections_id, sc.connection_status
FROM service_connections AS sc
WHERE NOT EXISTS (
    SELECT 1 FROM work_orders AS wo
    WHERE wo.connection_id = sc.connections_id
)
ORDER BY sc.connections_id;

-- Q6: Compare district average consumption to the full-dataset average.
SELECT c.district, ROUND(AVG(mr.consumption_m3), 2) AS district_average,
       ROUND((SELECT AVG(consumption_m3) FROM meter_readings), 2) AS overall_average
FROM customers AS c
JOIN service_connections AS sc ON sc.customer_id = c.customer_id
JOIN meter_readings AS mr ON mr.connection_id = sc.connections_id
GROUP BY c.district
ORDER BY district_average DESC;

-- EXTENDED PRACTICE 001: run and interpret this urban utility query.
SELECT customer_id, customer_name, account_status FROM customers 
WHERE district='Northbank' ORDER BY customer_name LIMIT 25;

SELECT reading_id, connection_id, consumption_m3 FROM meter_readings 
WHERE consumption_m3 >= 20 ORDER BY consumption_m3 DESC LIMIT 30;

SELECT work_order_id, issue_type, priority, work_order_status FROM work_orders 
WHERE priority='High' ORDER BY reported_date DESC LIMIT 25;


SELECT reading_method, ROUND(AVG(consumption_m3),2) AS avg_m3 FROM meter_readings 
GROUP BY reading_method ORDER BY avg_m3 DESC;

SELECT c.district, COUNT(wo.work_order_id) AS n FROM customers c 
JOIN service_connections sc ON sc.customer_id=c.customer_id 
JOIN work_orders wo ON wo.connection_id=sc.connections_id
 GROUP BY c.district ORDER BY n DESC;

SELECT connection_id, consumption_m3, RANK() OVER (ORDER BY consumption_m3 DESC) AS usage_rank 
FROM meter_readings ORDER BY usage_rank LIMIT 25;

SELECT work_order_id, DATEDIFF(COALESCE(resolved_date,CURDATE()),reported_date) 
AS age_days FROM work_orders ORDER BY age_days DESC LIMIT 25;

SELECT customer_id, customer_name, account_status FROM customers 
WHERE district='Lakeside' ORDER BY customer_name LIMIT 25;

SELECT reading_id, connection_id, consumption_m3 FROM meter_readings 
WHERE consumption_m3 >= 40 ORDER BY consumption_m3 DESC LIMIT 30;

SELECT work_order_id, issue_type, priority, work_order_status FROM work_orders 
WHERE priority='High' ORDER BY reported_date DESC LIMIT 25;

SELECT district, COUNT(*) AS n FROM customers GROUP BY district ORDER BY n DESC;

SELECT reading_method, ROUND(AVG(consumption_m3),2) AS avg_m3 FROM meter_readings 
GROUP BY reading_method ORDER BY avg_m3 DESC;

SELECT c.district, COUNT(wo.work_order_id) AS n FROM customers c 
JOIN service_connections sc ON sc.customer_id=c.customer_id 
JOIN work_orders wo ON wo.connection_id=sc.connections_id 
GROUP BY c.district ORDER BY n DESC;

SELECT connection_id, consumption_m3, RANK() 
OVER (ORDER BY consumption_m3 DESC) AS usage_rank 
FROM meter_readings ORDER BY usage_rank LIMIT 25;

SELECT work_order_id, DATEDIFF(COALESCE(resolved_date,CURDATE()),reported_date) 
AS age_days FROM work_orders ORDER BY age_days DESC LIMIT 25;

SELECT customer_id, customer_name, account_status FROM customers 
WHERE district='Southgate' ORDER BY customer_name LIMIT 25;

SELECT reading_id, connection_id, consumption_m3 FROM meter_readings 
WHERE consumption_m3 >= 60 ORDER BY consumption_m3 DESC LIMIT 30;

SELECT work_order_id, issue_type, priority, work_order_status 
FROM work_orders WHERE priority='High' ORDER BY reported_date DESC LIMIT 25;

SELECT district, COUNT(*) AS n FROM customers GROUP BY district ORDER BY n DESC;

SELECT reading_method, ROUND(AVG(consumption_m3),2) AS avg_m3 
FROM meter_readings GROUP BY reading_method ORDER BY avg_m3 DESC;

SELECT c.district, COUNT(wo.work_order_id) AS n FROM customers c 
JOIN service_connections sc ON sc.customer_id=c.customer_id JOIN work_orders wo ON wo.connection_id=sc.connections_id 
GROUP BY c.district ORDER BY n DESC;

SELECT connection_id, consumption_m3, 
RANK() OVER (ORDER BY consumption_m3 DESC) AS usage_rank FROM meter_readings 
ORDER BY usage_rank LIMIT 25;

SELECT work_order_id, DATEDIFF(COALESCE(resolved_date,CURDATE()),reported_date) 
AS age_days FROM work_orders ORDER BY age_days DESC LIMIT 25;

SELECT customer_id, customer_name, account_status FROM customers 
WHERE district='Market Ward' ORDER BY customer_name LIMIT 25;

SELECT reading_id, connection_id, consumption_m3 FROM meter_readings 
WHERE consumption_m3 >= 20 ORDER BY consumption_m3 DESC LIMIT 30;

SELECT work_order_id, issue_type, priority, work_order_status 
FROM work_orders WHERE priority='High' 
ORDER BY reported_date DESC LIMIT 25;

SELECT district, COUNT(*) AS n FROM customers GROUP BY district ORDER BY n DESC;

SELECT reading_method, ROUND(AVG(consumption_m3),2) AS avg_m3 FROM meter_readings 
GROUP BY reading_method ORDER BY avg_m3 DESC;

SELECT c.district, COUNT(wo.work_order_id) AS n FROM customers c 
JOIN service_connections sc ON sc.customer_id=c.customer_id 
JOIN work_orders wo ON wo.connection_id=sc.connections_id 
GROUP BY c.district ORDER BY n DESC;

SELECT connection_id, consumption_m3, RANK() OVER 
(ORDER BY consumption_m3 DESC) AS usage_rank 
FROM meter_readings ORDER BY usage_rank LIMIT 25;

SELECT work_order_id, DATEDIFF(COALESCE(resolved_date,CURDATE()),reported_date) 
AS age_days FROM work_orders ORDER BY age_days DESC LIMIT 25;

SELECT customer_id, customer_name, account_status FROM customers WHERE district='Riverside' ORDER BY customer_name LIMIT 25;

SELECT reading_id, connection_id, consumption_m3 FROM meter_readings WHERE consumption_m3 >= 40 ORDER BY consumption_m3 DESC LIMIT 30;

SELECT work_order_id, issue_type, priority, work_order_status FROM work_orders WHERE priority='High' ORDER BY reported_date DESC LIMIT 25;

SELECT district, COUNT(*) AS n FROM customers GROUP BY district ORDER BY n DESC;

SELECT reading_method, ROUND(AVG(consumption_m3),2) AS avg_m3 FROM meter_readings GROUP BY reading_method ORDER BY avg_m3 DESC;

SELECT c.district, COUNT(wo.work_order_id) AS n FROM customers c JOIN service_connections sc ON sc.customer_id=c.customer_id 
JOIN work_orders wo ON wo.connection_id=sc.connections_id GROUP BY c.district ORDER BY n DESC;

SELECT connection_id, consumption_m3, RANK() OVER (ORDER BY consumption_m3 DESC) AS usage_rank FROM meter_readings ORDER BY usage_rank LIMIT 25;

SELECT work_order_id, DATEDIFF(COALESCE(resolved_date,CURDATE()),reported_date) AS age_days FROM work_orders ORDER BY age_days DESC LIMIT 25;

SELECT customer_id, customer_name, account_status FROM customers WHERE district='Northbank' ORDER BY customer_name LIMIT 25;

SELECT reading_id, connection_id, consumption_m3 FROM meter_readings WHERE consumption_m3 >= 60 ORDER BY consumption_m3 DESC LIMIT 30;

SELECT work_order_id, issue_type, priority, work_order_status FROM work_orders WHERE priority='High' ORDER BY reported_date DESC LIMIT 25;

SELECT district, COUNT(*) AS n FROM customers GROUP BY district ORDER BY n DESC;

SELECT reading_method, ROUND(AVG(consumption_m3),2) AS avg_m3 FROM meter_readings GROUP BY reading_method ORDER BY avg_m3 DESC;

SELECT c.district, COUNT(wo.work_order_id) AS n FROM customers c JOIN service_connections sc ON sc.customer_id=c.customer_id JOIN work_orders wo
ON wo.connection_id=sc.connections_id GROUP BY c.district ORDER BY n DESC;

SELECT connection_id, consumption_m3, RANK() OVER (ORDER BY consumption_m3 DESC) AS usage_rank FROM meter_readings ORDER BY usage_rank LIMIT 25;

SELECT work_order_id, DATEDIFF(COALESCE(resolved_date,CURDATE()),reported_date) AS age_days FROM work_orders ORDER BY age_days DESC LIMIT 25;

SELECT customer_id, customer_name, account_status FROM customers WHERE district='Lakeside' ORDER BY customer_name LIMIT 25;

SELECT reading_id, connection_id, consumption_m3 FROM meter_readings WHERE consumption_m3 >= 20 ORDER BY consumption_m3 DESC LIMIT 30;

SELECT work_order_id, issue_type, priority, work_order_status FROM work_orders WHERE priority='High' ORDER BY reported_date DESC LIMIT 25;

SELECT district, COUNT(*) AS n FROM customers GROUP BY district ORDER BY n DESC;

SELECT reading_method, ROUND(AVG(consumption_m3),2) AS avg_m3 FROM meter_readings GROUP BY reading_method ORDER BY avg_m3 DESC;

SELECT c.district, COUNT(wo.work_order_id) AS n FROM customers c JOIN service_connections sc ON sc.customer_id=c.customer_id 
JOIN work_orders wo ON wo.connection_id=sc.connections_id GROUP BY c.district ORDER BY n DESC;

SELECT connection_id, consumption_m3, RANK() OVER (ORDER BY consumption_m3 DESC) AS usage_rank FROM meter_readings ORDER BY usage_rank LIMIT 25;

SELECT work_order_id, DATEDIFF(COALESCE(resolved_date,CURDATE()),reported_date) AS age_days FROM work_orders ORDER BY age_days DESC LIMIT 25;

SELECT customer_id, customer_name, account_status FROM customers WHERE district='Southgate' ORDER BY customer_name LIMIT 25;

SELECT reading_id, connection_id, consumption_m3 FROM meter_readings WHERE consumption_m3 >= 40 ORDER BY consumption_m3 DESC LIMIT 30;

SELECT work_order_id, issue_type, priority, work_order_status FROM work_orders WHERE priority='High' ORDER BY reported_date DESC LIMIT 25;

SELECT district, COUNT(*) AS n FROM customers GROUP BY district ORDER BY n DESC;

SELECT reading_method, ROUND(AVG(consumption_m3),2) AS avg_m3 FROM meter_readings GROUP BY reading_method ORDER BY avg_m3 DESC;

SELECT c.district, COUNT(wo.work_order_id) AS n FROM customers c JOIN service_connections sc ON sc.customer_id=c.customer_id JOIN work_orders wo
 ON wo.connection_id=sc.connections_id GROUP BY c.district ORDER BY n DESC;

SELECT connection_id, consumption_m3, RANK() OVER (ORDER BY consumption_m3 DESC) AS usage_rank FROM meter_readings ORDER BY usage_rank LIMIT 25;

SELECT work_order_id, DATEDIFF(COALESCE(resolved_date,CURDATE()),reported_date) AS age_days FROM work_orders ORDER BY age_days DESC LIMIT 25;

SELECT customer_id, customer_name, account_status FROM customers WHERE district='Market Ward' ORDER BY customer_name LIMIT 25;

SELECT reading_id, connection_id, consumption_m3 FROM meter_readings WHERE consumption_m3 >= 60 ORDER BY consumption_m3 DESC LIMIT 30;

SELECT work_order_id, issue_type, priority, work_order_status FROM work_orders WHERE priority='High' ORDER BY reported_date DESC LIMIT 25;

SELECT district, COUNT(*) AS n FROM customers GROUP BY district ORDER BY n DESC;

SELECT reading_method, ROUND(AVG(consumption_m3),2) AS avg_m3 FROM meter_readings GROUP BY reading_method ORDER BY avg_m3 DESC;

SELECT c.district, COUNT(wo.work_order_id) AS n FROM customers c JOIN service_connections sc ON sc.customer_id=c.customer_id 
JOIN work_orders wo ON wo.connection_id=sc.connections_id GROUP BY c.district ORDER BY n DESC;

SELECT connection_id, consumption_m3, RANK() OVER (ORDER BY consumption_m3 DESC) AS usage_rank FROM meter_readings ORDER BY usage_rank LIMIT 25;

SELECT work_order_id, DATEDIFF(COALESCE(resolved_date,CURDATE()),reported_date) AS age_days FROM work_orders ORDER BY age_days DESC LIMIT 25;

SELECT customer_id, customer_name, account_status FROM customers WHERE district='Riverside' ORDER BY customer_name LIMIT 25;

SELECT reading_id, connection_id, consumption_m3 FROM meter_readings WHERE consumption_m3 >= 20 ORDER BY consumption_m3 DESC LIMIT 30;

SELECT work_order_id, issue_type, priority, work_order_status FROM work_orders WHERE priority='High' ORDER BY reported_date DESC LIMIT 25;

SELECT district, COUNT(*) AS n FROM customers GROUP BY district ORDER BY n DESC;

START TRANSACTION;

-- Transaction step 1: change a connection status.
UPDATE urban.service_connections
SET connection_status = 'Under Repair'
WHERE connections_id = 'W0006'
LIMIT 1;
-- Transaction step 2: mark the first savepoint.
SAVEPOINT urban_update1;

-- Transaction step 3: make a second change after that savepoint.
UPDATE urban.service_connections
SET connection_status = 'Disconnected'
WHERE connections_id = 'W0001'
LIMIT 1;

-- Transaction step 4: mark a second savepoint.
SAVEPOINT urban_update2;

-- Transaction step 5: add a work order (unique practice ID).
INSERT INTO work_orders
    (work_order_id, connection_id, issue_type, reported_date,
     priority, work_order_status, resolved_date)
VALUES
    ('WO-TXN-FINAL', 'W0006', 'Leak Inspection', '2026-11-20',
     'High', 'Open', NULL);

-- Transaction step 6: inspect changes before rollback.
SELECT connections_id, connection_status
FROM service_connections
WHERE connections_id IN ('W0001', 'W0006');

SELECT * FROM work_orders WHERE work_order_id = 'WO-TXN-FINAL';

-- FINAL SQL COMMAND: undo updates/inserts made after urban_update1.
ROLLBACK TO SAVEPOINT urban_update1;