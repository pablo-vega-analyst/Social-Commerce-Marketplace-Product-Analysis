-- Analyzing Social Commerce Marketplace Product Data

-- Step 1. Join Orders, Users, and Products Tables

CREATE TABLE full_orders AS
SELECT
	o.order_id, o.user_id, o.product_id, o.order_date, o.num_items, o.bundle_adopted,
	u.signup_date, u.region, u.device, u.platform, u.buyer_type,
	p.category, p.subcategory, p.brand, p.price
FROM
	orders_staging AS o
JOIN
	users_staging AS u ON o.user_id = u.user_id
JOIN
	products_staging AS p ON o.product_id = p.product_id;
    
SELECT *
FROM full_orders
LIMIT 10;

-- create column for total amount
ALTER TABLE full_orders
ADD COLUMN total_amount DOUBLE;

UPDATE full_orders
SET total_amount = num_items * price;

-- identify when bundle & save feature was introduced
WITH bundle_orders_cte AS (
	SELECT
		order_id, order_date, bundle_adopted
	FROM full_orders
    WHERE bundle_adopted = 1
)
SELECT
	order_date, bundle_adopted
FROM 
	bundle_orders_cte
ORDER BY
	order_date
LIMIT 10;

-- identify earliest date in table
SELECT
	order_date,
    bundle_adopted
FROM
	full_orders
ORDER BY
	order_date
LIMIT 10;

-- identify the number of unique users and the number of unique users who used bundle feature
SELECT
    COUNT(DISTINCT user_id) AS total_unique_users,
    COUNT(DISTINCT CASE WHEN bundle_adopted = 1 THEN user_id END) AS bundle_unique_users
FROM
	full_orders;
    
SELECT
	AVG(total_amount)
FROM
	full_orders
WHERE
	bundle_adopted = 0;

-- Step 2. Slice Key Metrics By Key Dimensions

-- look at adoption rate per day
SELECT 
    order_date,
    COUNT(CASE 
			WHEN bundle_adopted = 1 THEN 1
            END) AS bundle_orders,
    COUNT(*) AS total_orders,
    ROUND(100 * COUNT(CASE
						WHEN bundle_adopted = 1 THEN 1
						END) / COUNT(*), 2) AS adoption_rate
FROM
	full_orders
GROUP BY
	order_date
ORDER BY
	order_date;
    
-- look at adoption rate per week
SELECT
	YEARWEEK(order_date) AS year_week,
    MIN(order_date) AS week_start,
    MAX(order_date) AS week_end,
    COUNT(CASE
			WHEN bundle_adopted = 1 THEN 1
            END) AS bundle_orders,
    COUNT(*) AS total_orders,
    ROUND(100 * COUNT(CASE
						WHEN bundle_adopted = 1 THEN 1
						END) / COUNT(*), 2) AS adoption_rate
FROM
	full_orders
GROUP BY
	YEARWEEK(order_date)
ORDER BY
	YEARWEEK(order_date);

-- look at adoption rate per month
SELECT
	DATE_FORMAT(order_date, '%Y-%m') AS `year_month`,
    COUNT(CASE
			WHEN bundle_adopted = 1 THEN 1
            END) AS bundle_orders,
    COUNT(*) AS total_orders,
    ROUND(100 * COUNT(CASE
						WHEN bundle_adopted = 1 THEN 1
						END) / COUNT(*), 2) AS adoption_rate
FROM
	full_orders
GROUP BY
	DATE_FORMAT(order_date, '%Y-%m')
ORDER BY
	DATE_FORMAT(order_date, '%Y-%m');
    
-- look at cumulative daily adoption rate for orders with more than 1 item
WITH adoption_rate_cte AS
(
SELECT
	order_date,
    COUNT(CASE
			WHEN bundle_adopted = 1 THEN 1
            END) AS bundle_orders,
    COUNT(*) AS total_orders,
    ROUND(100* COUNT(CASE
						WHEN bundle_adopted = 1 THEN 1
						END) / COUNT(*), 2) AS adoption_rate
FROM
	full_orders
WHERE
	num_items > 1
GROUP BY
	order_date
ORDER BY
	order_date
)
SELECT
	order_date,
    bundle_orders,
    total_orders,
    adoption_rate,
    SUM(bundle_orders) OVER(ORDER BY order_date) AS cumulative_bundle_orders,
    SUM(total_orders) OVER(ORDER BY order_date) AS cumulative_total_orders,
    ROUND(100 * SUM(bundle_orders) OVER(ORDER BY order_date) / SUM(total_orders) OVER(ORDER BY order_date), 2)
    AS cumulative_adoption_rate
FROM
	adoption_rate_cte;
    
-- look at cumulative weekly adoption rate for orders with more than 1 item
WITH adoption_rate_cte AS
(
SELECT
	YEARWEEK(order_date) AS year_week,
    MIN(order_date) AS week_start,
    MAX(order_date) AS week_end,
    COUNT(CASE
			WHEN bundle_adopted = 1 THEN 1
            END) AS bundle_orders,
    COUNT(*) AS total_orders,
    ROUND(100 * COUNT(CASE
						WHEN bundle_adopted = 1 THEN 1
						END) / COUNT(*), 2) AS adoption_rate
FROM
	full_orders
WHERE
	num_items > 1
GROUP BY
	YEARWEEK(order_date)
ORDER BY
	YEARWEEK(order_date)
)
SELECT
	year_week,
    week_start,
    week_end,
    bundle_orders,
    total_orders,
    adoption_rate,
    SUM(bundle_orders) OVER(ORDER BY year_week) AS cumulative_bundle_orders,
    SUM(total_orders) OVER(ORDER BY year_week) AS cumulative_total_orders,
    ROUND(100 * SUM(bundle_orders) OVER(ORDER BY year_week) / SUM(total_orders) OVER(ORDER BY year_week), 2)
    AS cumulative_adoption_rate
FROM
	adoption_rate_cte;
    
-- look at cumulative monthly adoption rate for orders with more than 1 item
WITH adoption_rate_cte AS 
(
SELECT
	DATE_FORMAT(order_date, '%Y-%m') AS `year_month`,
    COUNT(CASE
			WHEN bundle_adopted = 1 THEN 1
            END) AS bundle_orders,
    COUNT(*) AS total_orders,
    ROUND(100 * COUNT(CASE
						WHEN bundle_adopted = 1 THEN 1
						END) / COUNT(*), 2) AS adoption_rate
FROM
	full_orders
WHERE
	num_items > 1
GROUP BY
	DATE_FORMAT(order_date, '%Y-%m')
ORDER BY
	DATE_FORMAT(order_date, '%Y-%m')
)
SELECT
	`year_month`,
    bundle_orders,
    total_orders,
    adoption_rate,
    SUM(bundle_orders) OVER(ORDER BY `year_month`) AS cumulative_bundle_orders,
    SUM(total_orders) OVER(ORDER BY `year_month`) AS cumulative_total_orders,
    ROUND(100 * SUM(bundle_orders) OVER(ORDER BY `year_month`) / SUM(total_orders) OVER(ORDER BY `year_month`), 2)
    AS cumulative_adoption_rate
FROM
	adoption_rate_cte;

-- slice daily adoption rate by buyer type
SELECT
	order_date,
    buyer_type,
    COUNT(CASE
			WHEN bundle_adopted = 1 THEN 1
            END) AS bundle_orders,
    COUNT(*) AS total_orders,
    ROUND(100 * COUNT(CASE
						WHEN bundle_adopted = 1 THEN 1
						END) / COUNT(*), 2) AS adoption_rate
FROM
	full_orders
WHERE
	num_items > 1
GROUP BY
	order_date, buyer_type
ORDER BY
	order_date;

-- slice cumulative daily adoption rate by buyer type
WITH dates_cte AS (
    SELECT
		DISTINCT order_date
    FROM
		full_orders
),
buyer_types_cte AS (
    SELECT
		DISTINCT buyer_type
    FROM
		full_orders
),
calendar_cte AS (
    SELECT
		d.order_date,
        b.buyer_type
    FROM
		dates_cte d
    CROSS JOIN
		buyer_types_cte b
),
daily_totals_cte AS (
    SELECT 
        order_date,
        buyer_type,
        COUNT(CASE
				WHEN bundle_adopted = 1 THEN 1
                END) AS bundle_orders,
        COUNT(*) AS total_orders
    FROM
		full_orders
    GROUP BY
		order_date,
		buyer_type
),
filled_cte AS (
    SELECT 
        c.order_date,
        c.buyer_type,
        COALESCE(dt.bundle_orders, 0) AS bundle_orders,
        COALESCE(dt.total_orders, 0) AS total_orders
    FROM
		calendar_cte c
    LEFT JOIN
		daily_totals_cte dt
		ON c.order_date = dt.order_date
		AND c.buyer_type = dt.buyer_type
),
cumulative_cte AS (
    SELECT 
        order_date,
        buyer_type,
        SUM(bundle_orders) OVER (PARTITION BY buyer_type ORDER BY order_date) AS cumulative_bundle_orders,
        SUM(total_orders) OVER (PARTITION BY buyer_type ORDER BY order_date) AS cumulative_total_orders
    FROM
		filled_cte
)
SELECT 
    order_date,
    ROUND(
		SUM(CASE WHEN buyer_type = 'New' THEN cumulative_bundle_orders END) * 100 /
        NULLIF(SUM(CASE WHEN buyer_type = 'New' THEN cumulative_total_orders END), 0), 2
    ) AS cumulative_new_buyer_adoption,
    ROUND(
        SUM(CASE WHEN buyer_type = 'Returning' THEN cumulative_bundle_orders END) * 100 /
        NULLIF(SUM(CASE WHEN buyer_type = 'Returning' THEN cumulative_total_orders END), 0), 2
    ) AS cumulative_returning_buyer_adoption,
    ROUND(
        SUM(CASE WHEN buyer_type = 'Guest' THEN cumulative_bundle_orders END) * 100 /
        NULLIF(SUM(CASE WHEN buyer_type = 'Guest' THEN cumulative_total_orders END), 0), 2
    ) AS cumulative_guest_buyer_adoption
FROM cumulative_cte
GROUP BY order_date
ORDER BY order_date;

-- slice weekly adoption rate by buyer type
SELECT
	YEARWEEK(order_date) AS year_week,
    MIN(order_date) AS week_start,
    MAX(order_date) AS week_end,
    buyer_type,
    COUNT(CASE
			WHEN bundle_adopted = 1 THEN 1
            END) AS bundle_orders,
    COUNT(*) AS total_orders,
    ROUND(100 * COUNT(CASE
						WHEN bundle_adopted = 1 THEN 1
						END) / COUNT(*), 2) AS adoption_rate
FROM
	full_orders
WHERE
	num_items > 1
GROUP BY
	YEARWEEK(order_date), buyer_type
ORDER BY
	YEARWEEK(order_date);

-- slice cumulative weekly adoption rate by buyer type
WITH weeks_cte AS (
    SELECT 
        YEARWEEK(order_date) AS year_week,
        MIN(order_date) AS week_start,
        MAX(order_date) AS week_end
    FROM
		full_orders
    GROUP BY
		YEARWEEK(order_date)
),
weekly_totals_cte AS (
    SELECT 
        YEARWEEK(order_date) AS year_week,
        buyer_type,
        COUNT(CASE WHEN bundle_adopted = 1 THEN 1 END) AS bundle_orders,
        COUNT(*) AS total_orders
    FROM
		full_orders
    GROUP BY
		YEARWEEK(order_date),
        buyer_type
),
cumulative_cte AS (
    SELECT 
        wt.year_week,
        w.week_start,
        w.week_end,
        wt.buyer_type,
        SUM(wt.bundle_orders) OVER (PARTITION BY wt.buyer_type ORDER BY wt.year_week) AS cumulative_bundle_orders,
        SUM(wt.total_orders) OVER (PARTITION BY wt.buyer_type ORDER BY wt.year_week) AS cumulative_total_orders
    FROM
		weekly_totals_cte wt
    JOIN
		weeks_cte w ON wt.year_week = w.year_week
)
SELECT 
    year_week,
    week_start,
    week_end,
    ROUND(
        SUM(CASE WHEN buyer_type = 'New' THEN cumulative_bundle_orders END) * 100 /
        NULLIF(SUM(CASE WHEN buyer_type = 'New' THEN cumulative_total_orders END), 0), 2
    ) AS cumulative_new_buyer_adoption,
    ROUND(
        SUM(CASE WHEN buyer_type = 'Returning' THEN cumulative_bundle_orders END) * 100 /
        NULLIF(SUM(CASE WHEN buyer_type = 'Returning' THEN cumulative_total_orders END), 0), 2
    ) AS cumulative_returning_buyer_adoption,
    ROUND(
        SUM(CASE WHEN buyer_type = 'Guest' THEN cumulative_bundle_orders END) * 100 /
        NULLIF(SUM(CASE WHEN buyer_type = 'Guest' THEN cumulative_total_orders END), 0), 2
    ) AS cumulative_guest_buyer_adoption
FROM
	cumulative_cte
GROUP BY
	year_week, week_start,
    week_end
ORDER BY
	year_week;

-- slice monthly adoption rate by buyer type
SELECT
	DATE_FORMAT(order_date, '%Y-%m') AS `year_month`,
    buyer_type,
    COUNT(CASE
			WHEN bundle_adopted = 1 THEN 1
            END) AS bundle_orders,
    COUNT(*) AS total_orders,
    ROUND(100 * COUNT(CASE
			WHEN bundle_adopted = 1 THEN 1
            END) / COUNT(*), 2) AS adoption_rate
FROM
	full_orders
WHERE
	num_items > 1
GROUP BY
	DATE_FORMAT(order_date, '%Y-%m'), buyer_type
ORDER BY
	DATE_FORMAT(order_date, '%Y-%m');
    
-- slice cumulative monthly adoption rate by buyer type
WITH months_cte AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS `year_month`
    FROM
		full_orders
    GROUP BY
		DATE_FORMAT(order_date, '%Y-%m')
),
monthly_totals_cte AS (
    SELECT 
        DATE_FORMAT(order_date, '%Y-%m') AS `year_month`,
        buyer_type,
        COUNT(CASE WHEN bundle_adopted = 1 THEN 1 END) AS bundle_orders,
        COUNT(*) AS total_orders
    FROM
		full_orders
    GROUP BY
		DATE_FORMAT(order_date, '%Y-%m'),
        buyer_type
),
cumulative_cte AS (
    SELECT 
        mt.year_month,
        mt.buyer_type,
        SUM(mt.bundle_orders) OVER (PARTITION BY mt.buyer_type ORDER BY mt.year_month) AS cumulative_bundle_orders,
        SUM(mt.total_orders) OVER (PARTITION BY mt.buyer_type ORDER BY mt.year_month) AS cumulative_total_orders
    FROM
		monthly_totals_cte mt
    JOIN
		months_cte m ON mt.year_month = m.year_month
)
SELECT 
    `year_month`,
    ROUND(
        SUM(CASE WHEN buyer_type = 'New' THEN cumulative_bundle_orders END) * 100 /
        NULLIF(SUM(CASE WHEN buyer_type = 'New' THEN cumulative_total_orders END), 0), 2
    ) AS cumulative_new_buyer_adoption,
    ROUND(
        SUM(CASE WHEN buyer_type = 'Returning' THEN cumulative_bundle_orders END) * 100 /
        NULLIF(SUM(CASE WHEN buyer_type = 'Returning' THEN cumulative_total_orders END), 0), 2
    ) AS cumulative_returning_buyer_adoption,
    ROUND(
        SUM(CASE WHEN buyer_type = 'Guest' THEN cumulative_bundle_orders END) * 100 /
        NULLIF(SUM(CASE WHEN buyer_type = 'Guest' THEN cumulative_total_orders END), 0), 2
    ) AS cumulative_guest_buyer_adoption
FROM
	cumulative_cte
GROUP BY
	`year_month`
ORDER BY
	`year_month`;
    
-- slice daily adoption rate by region
SELECT
	order_date,
    region,
    COUNT(CASE
			WHEN bundle_adopted = 1 THEN 1
            END) AS bundle_orders,
    COUNT(*) AS total_orders,
    ROUND(100 * COUNT(CASE
						WHEN bundle_adopted = 1 THEN 1
						END) / COUNT(*), 2) AS adoption_rate
FROM
	full_orders
WHERE
	num_items > 1
GROUP BY
	order_date,
    region
ORDER BY
	order_date;
    
-- slice cumulative daily adoption rate by region
WITH dates_cte AS (
    SELECT
		DISTINCT order_date
    FROM
		full_orders
),
regions_cte AS (
    SELECT
		DISTINCT region
    FROM
		full_orders
),
calendar_cte AS (
    SELECT
		d.order_date,
        r.region
    FROM
		dates_cte d
    CROSS JOIN
		regions_cte r
),
daily_totals_cte AS (
    SELECT 
        order_date,
        region,
        COUNT(CASE
				WHEN bundle_adopted = 1 THEN 1
                END) AS bundle_orders,
        COUNT(*) AS total_orders
    FROM
		full_orders
    GROUP BY
		order_date,
		region
),
filled_cte AS (
    SELECT 
        c.order_date,
        c.region,
        COALESCE(dt.bundle_orders, 0) AS bundle_orders,
        COALESCE(dt.total_orders, 0) AS total_orders
    FROM
		calendar_cte c
    LEFT JOIN
		daily_totals_cte dt
		ON c.order_date = dt.order_date
		AND c.region = dt.region
),
cumulative_cte AS (
    SELECT 
        order_date,
        region,
        SUM(bundle_orders) OVER (PARTITION BY region ORDER BY order_date) AS cumulative_bundle_orders,
        SUM(total_orders) OVER (PARTITION BY region ORDER BY order_date) AS cumulative_total_orders
    FROM
		filled_cte
)
SELECT 
    order_date,
    ROUND(
		SUM(CASE WHEN region = 'East Coast' THEN cumulative_bundle_orders END) * 100 /
        NULLIF(SUM(CASE WHEN region = 'East Coast' THEN cumulative_total_orders END), 0), 2
    ) AS cumulative_east_coast_adoption,
    ROUND(
        SUM(CASE WHEN region = 'Midwest' THEN cumulative_bundle_orders END) * 100 /
        NULLIF(SUM(CASE WHEN region = 'Midwest' THEN cumulative_total_orders END), 0), 2
    ) AS cumulative_midwest_adoption,
    ROUND(
        SUM(CASE WHEN region = 'South' THEN cumulative_bundle_orders END) * 100 /
        NULLIF(SUM(CASE WHEN region = 'South' THEN cumulative_total_orders END), 0), 2
    ) AS cumulative_south_adoption,
    ROUND(
        SUM(CASE WHEN region = 'West Coast' THEN cumulative_bundle_orders END) * 100 /
        NULLIF(SUM(CASE WHEN region = 'West Coast' THEN cumulative_total_orders END), 0), 2
    ) AS cumulative_west_coast_adoption
FROM
	cumulative_cte
GROUP BY
	order_date
ORDER BY
	order_date;

-- slice weekly adoption rate by region
SELECT
	YEARWEEK(order_date) AS year_week,
    MIN(order_date) AS week_start,
    MAX(order_date) AS week_end,
    region,
    COUNT(CASE
			WHEN bundle_adopted = 1 THEN 1
            END) AS bundle_orders,
    COUNT(*) AS total_orders,
    ROUND(100 * COUNT(CASE
						WHEN bundle_adopted = 1 THEN 1
						END) / COUNT(*), 2) AS adoption_rate
FROM
	full_orders
WHERE
	num_items > 1
GROUP BY
	YEARWEEK(order_date),
    region
ORDER BY
	YEARWEEK(order_date);

-- slice cumulative weekly adoption rate by region
WITH weeks_cte AS (
    SELECT 
        YEARWEEK(order_date) AS year_week,
        MIN(order_date) AS week_start,
        MAX(order_date) AS week_end
    FROM full_orders
    GROUP BY YEARWEEK(order_date)
),
regions_cte AS (
    SELECT DISTINCT region
    FROM full_orders
),
calendar AS (
    SELECT 
        w.year_week,
        w.week_start,
        w.week_end,
        r.region
    FROM weeks_cte w
    CROSS JOIN regions_cte r
),
weekly_totals_cte AS (
    SELECT 
        YEARWEEK(order_date) AS year_week,
        region,
        COUNT(CASE WHEN bundle_adopted = 1 THEN 1 END) AS bundle_orders,
        COUNT(*) AS total_orders
    FROM full_orders
    GROUP BY YEARWEEK(order_date), region
),
filled_cte AS (
    SELECT 
        c.year_week,
        c.week_start,
        c.week_end,
        c.region,
        COALESCE(wt.bundle_orders, 0) AS bundle_orders,
        COALESCE(wt.total_orders, 0) AS total_orders
    FROM calendar c
    LEFT JOIN weekly_totals_cte wt
      ON c.year_week = wt.year_week
     AND c.region = wt.region
),
cumulative_cte AS (
    SELECT 
        year_week,
        week_start,
        week_end,
        region,
        SUM(bundle_orders) OVER (PARTITION BY region ORDER BY year_week) AS cumulative_bundle_orders,
        SUM(total_orders) OVER (PARTITION BY region ORDER BY year_week) AS cumulative_total_orders
    FROM filled_cte
)
SELECT 
    year_week,
    week_start,
    week_end,
    ROUND(
        SUM(CASE WHEN region = 'East Coast' THEN cumulative_bundle_orders END) * 100 /
        NULLIF(SUM(CASE WHEN region = 'East Coast' THEN cumulative_total_orders END), 0), 2
    ) AS cumulative_east_coast_adoption,
    ROUND(
        SUM(CASE WHEN region = 'Midwest' THEN cumulative_bundle_orders END) * 100 /
        NULLIF(SUM(CASE WHEN region = 'Midwest' THEN cumulative_total_orders END), 0), 2
    ) AS cumulative_midwest_adoption,
    ROUND(
        SUM(CASE WHEN region = 'South' THEN cumulative_bundle_orders END) * 100 /
        NULLIF(SUM(CASE WHEN region = 'South' THEN cumulative_total_orders END), 0), 2
    ) AS cumulative_south_adoption,
    ROUND(
        SUM(CASE WHEN region = 'West Coast' THEN cumulative_bundle_orders END) * 100 /
        NULLIF(SUM(CASE WHEN region = 'West Coast' THEN cumulative_total_orders END), 0), 2
    ) AS cumulative_west_coast_adoption
FROM
	cumulative_cte
GROUP BY
	year_week, week_start,
    week_end
ORDER BY year_week;

-- slice monthly adoption rate by region
SELECT
	DATE_FORMAT(order_date, '%Y-%m') AS `year_month`,
    region,
    COUNT(CASE
			WHEN bundle_adopted = 1 THEN 1
            END) AS bundle_orders,
    COUNT(*) AS total_orders,
    ROUND(100 * COUNT(CASE
						WHEN bundle_adopted = 1 THEN 1
						END) / COUNT(*), 2) AS adoption_rate
FROM
	full_orders
WHERE
	num_items > 1
GROUP BY
	DATE_FORMAT(order_date, '%Y-%m'),
    region
ORDER BY
	DATE_FORMAT(order_date, '%Y-%m');
    
-- slice cumulative daily adoption rate by platform
SELECT DISTINCT platform
FROM full_orders;

WITH dates_cte AS (
    SELECT
		DISTINCT order_date
    FROM
		full_orders
),
platforms_cte AS (
    SELECT
		DISTINCT platform
    FROM
		full_orders
),
calendar_cte AS (
    SELECT
		d.order_date,
        p.platform
    FROM
		dates_cte d
    CROSS JOIN
		platforms_cte p
),
daily_totals_cte AS (
    SELECT 
        order_date,
        platform,
        COUNT(CASE
				WHEN bundle_adopted = 1 THEN 1
                END) AS bundle_orders,
        COUNT(*) AS total_orders
    FROM
		full_orders
    GROUP BY
		order_date,
		platform
),
filled_cte AS (
    SELECT 
        c.order_date,
        c.platform,
        COALESCE(dt.bundle_orders, 0) AS bundle_orders,
        COALESCE(dt.total_orders, 0) AS total_orders
    FROM
		calendar_cte c
    LEFT JOIN
		daily_totals_cte dt
		ON c.order_date = dt.order_date
		AND c.platform = dt.platform
),
cumulative_cte AS (
    SELECT 
        order_date,
        platform,
        SUM(bundle_orders) OVER (PARTITION BY platform ORDER BY order_date) AS cumulative_bundle_orders,
        SUM(total_orders) OVER (PARTITION BY platform ORDER BY order_date) AS cumulative_total_orders
    FROM
		filled_cte
)
SELECT 
    order_date,
    ROUND(
		SUM(CASE WHEN platform = 'App' THEN cumulative_bundle_orders END) * 100 /
        NULLIF(SUM(CASE WHEN platform = 'App' THEN cumulative_total_orders END), 0), 2
    ) AS cumulative_app_adoption,
    ROUND(
        SUM(CASE WHEN platform = 'Web' THEN cumulative_bundle_orders END) * 100 /
        NULLIF(SUM(CASE WHEN platform = 'Web' THEN cumulative_total_orders END), 0), 2
    ) AS cumulative_web_adoption
FROM
	cumulative_cte
GROUP BY
	order_date
ORDER BY
	order_date;

-- slice cumulative weekly adoption rate by platform
WITH weeks_cte AS (
    SELECT 
        YEARWEEK(order_date) AS year_week,
        MIN(order_date) AS week_start,
        MAX(order_date) AS week_end
    FROM full_orders
    GROUP BY YEARWEEK(order_date)
),
platforms_cte AS (
    SELECT DISTINCT platform
    FROM full_orders
),
calendar AS (
    SELECT 
        w.year_week,
        w.week_start,
        w.week_end,
        p.platform
    FROM weeks_cte w
    CROSS JOIN platforms_cte p
),
weekly_totals_cte AS (
    SELECT 
        YEARWEEK(order_date) AS year_week,
        platform,
        COUNT(CASE WHEN bundle_adopted = 1 THEN 1 END) AS bundle_orders,
        COUNT(*) AS total_orders
    FROM full_orders
    GROUP BY YEARWEEK(order_date), platform
),
filled_cte AS (
    SELECT 
        c.year_week,
        c.week_start,
        c.week_end,
        c.platform,
        COALESCE(wt.bundle_orders, 0) AS bundle_orders,
        COALESCE(wt.total_orders, 0) AS total_orders
    FROM calendar c
    LEFT JOIN weekly_totals_cte wt
      ON c.year_week = wt.year_week
     AND c.platform = wt.platform
),
cumulative_cte AS (
    SELECT 
        year_week,
        week_start,
        week_end,
        platform,
        SUM(bundle_orders) OVER (PARTITION BY platform ORDER BY year_week) AS cumulative_bundle_orders,
        SUM(total_orders) OVER (PARTITION BY platform ORDER BY year_week) AS cumulative_total_orders
    FROM filled_cte
)
SELECT 
    year_week,
    week_start,
    week_end,
    ROUND(
        SUM(CASE WHEN platform = 'App' THEN cumulative_bundle_orders END) * 100 /
        NULLIF(SUM(CASE WHEN platform = 'App' THEN cumulative_total_orders END), 0), 2
    ) AS cumulative_app_adoption,
    ROUND(
        SUM(CASE WHEN platform = 'Web' THEN cumulative_bundle_orders END) * 100 /
        NULLIF(SUM(CASE WHEN platform = 'Web' THEN cumulative_total_orders END), 0), 2
    ) AS cumulative_web_adoption
FROM
	cumulative_cte
GROUP BY
	year_week, week_start,
	week_end
ORDER BY
	year_week;
    
-- for every day, get average order value (AOV) of orders with and without bundle & save feature
SELECT
	order_date,
    bundle_adopted,
    ROUND(AVG(total_amount), 2) AS aov
FROM
	full_orders
GROUP BY
	order_date,
    bundle_adopted
ORDER BY
	order_date;

SELECT
	order_date,
	ROUND(AVG(CASE
				WHEN bundle_adopted = 1 THEN total_amount
                END), 2) AS bundle_adopted_aov,
    ROUND(AVG(CASE
				WHEN bundle_adopted = 0 THEN total_amount
                END), 2) AS bundle_not_adopted_aov
FROM
	full_orders
GROUP BY
	order_date
ORDER BY
	order_date;
    
-- for every week, get average order value (AOV) of orders with and without bundle & save feature
SELECT
	YEARWEEK(order_date) AS year_week,
    MIN(order_date) AS week_start,
    MAX(order_date) AS week_end,
    bundle_adopted,
    ROUND(AVG(total_amount), 2) AS aov
FROM
	full_orders
GROUP BY
	YEARWEEK(order_date),
    bundle_adopted
ORDER BY
	YEARWEEK(order_date);
    
SELECT
	YEARWEEK(order_date) AS year_week,
    MIN(order_date) AS week_start,
    MAX(order_date) AS week_end,
    ROUND(AVG(CASE
			WHEN bundle_adopted = 1 THEN total_amount
            END), 2) AS bundle_adopted_aov,
    ROUND(AVG(CASE
			WHEN bundle_adopted = 0 THEN total_amount
            END), 2) AS bundle_not_adopted_aov
FROM
	full_orders
GROUP BY
	year_week
ORDER BY
	year_week;
    
-- for every month, get average order value (AOV) of orders with and without bundle & save feature
SELECT
	DATE_FORMAT(order_date, '%Y-%m') AS `year_month`,
    bundle_adopted,
    ROUND(AVG(total_amount), 2) AS aov
FROM
	full_orders
GROUP BY
	DATE_FORMAT(order_date, '%Y-%m'),
    bundle_adopted
ORDER BY
	DATE_FORMAT(order_date, '%Y-%m');
    
SELECT
	DATE_FORMAT(order_date, '%Y-%m') AS `year_month`,
    ROUND(AVG(CASE
			WHEN bundle_adopted = 1 THEN total_amount
            END), 2) AS bundle_adopted_aov,
    ROUND(AVG(CASE
			WHEN bundle_adopted = 0 THEN total_amount
            END), 2) AS bundle_not_adopted_aov
FROM
	full_orders
GROUP BY
	DATE_FORMAT(order_date, '%Y-%m')
ORDER BY
	DATE_FORMAT(order_date, '%Y-%m');
    
-- for every day, slice average order value (AOV) by buyer type
SELECT
	order_date,
    buyer_type,
    ROUND(AVG(total_amount), 2) AS aov
FROM
	full_orders
GROUP BY
	order_date,
    buyer_type
ORDER BY
	order_date;

SELECT
	order_date,
    ROUND(AVG(CASE
				WHEN buyer_type = 'Guest' THEN total_amount
				END), 2) AS guest_aov,
    ROUND(AVG(CASE
				WHEN buyer_type = 'New' THEN total_amount
				END), 2) AS new_aov,
    ROUND(AVG(CASE
				WHEN buyer_type = 'Returning' THEN total_amount
				END), 2) AS returning_aov
FROM
	full_orders
GROUP BY
	order_date
ORDER BY
	order_date;

-- for every day, slice average order value (AOV) by buyer type and bundle adopted
SELECT
	order_date,
    ROUND(AVG(CASE
				WHEN bundle_adopted = 1 AND buyer_type = 'Guest' THEN total_amount
				END), 2) AS guest_bundle_aov,
    ROUND(AVG(CASE
				WHEN bundle_adopted = 0 AND buyer_type = 'Guest' THEN total_amount
				END), 2) AS guest_no_bundle_aov,
    ROUND(AVG(CASE
				WHEN bundle_adopted = 1 AND buyer_type = 'New' THEN total_amount
				END), 2) AS new_bundle_aov,
    ROUND(AVG(CASE
				WHEN bundle_adopted = 0 AND buyer_type = 'New' THEN total_amount
				END), 2) AS new_no_bundle_aov,
    ROUND(AVG(CASE
				WHEN bundle_adopted = 1 AND buyer_type = 'Returning' THEN total_amount
				END), 2) AS returning_bundle_aov,
    ROUND(AVG(CASE
				WHEN bundle_adopted = 0 AND buyer_type = 'Returning' THEN total_amount
				END), 2) AS returning_no_bundle_aov
FROM
	full_orders
GROUP BY
	order_date
ORDER BY
	order_date;
    
-- for every week, slice average order value (AOV) by buyer type
SELECT
	YEARWEEK(order_date) AS year_week,
    MIN(order_date) AS week_start,
    MAX(order_date) AS week_end,
    buyer_type,
    ROUND(AVG(total_amount), 2) AS aov
FROM
	full_orders
GROUP BY
	YEARWEEK(order_date),
    buyer_type
ORDER BY
	YEARWEEK(order_date);
    
SELECT
	YEARWEEK(order_date) AS year_week,
    ROUND(AVG(CASE
				WHEN buyer_type = 'Guest' THEN total_amount
				END), 2) AS guest_aov,
    ROUND(AVG(CASE
				WHEN buyer_type = 'New' THEN total_amount
				END), 2) AS new_aov,
    ROUND(AVG(CASE
				WHEN buyer_type = 'Returning' THEN total_amount
				END), 2) AS returning_aov
FROM
	full_orders
GROUP BY
	YEARWEEK(order_date)
ORDER BY
	YEARWEEK(order_date);
    
-- for every week, slice average order value (AOV) by buyer type and bundle adopted
SELECT
	YEARWEEK(order_date) AS year_week,
    ROUND(AVG(CASE
				WHEN bundle_adopted = 1 AND buyer_type = 'Guest' THEN total_amount
				END), 2) AS guest_bundle_aov,
    ROUND(AVG(CASE
				WHEN bundle_adopted = 0 AND buyer_type = 'Guest' THEN total_amount
				END), 2) AS guest_no_bundle_aov,
    ROUND(AVG(CASE
				WHEN bundle_adopted = 1 AND buyer_type = 'New' THEN total_amount
				END), 2) AS new_bundle_aov,
    ROUND(AVG(CASE
				WHEN bundle_adopted = 0 AND buyer_type = 'New' THEN total_amount
				END), 2) AS new_no_bundle_aov,
    ROUND(AVG(CASE
				WHEN bundle_adopted = 1 AND buyer_type = 'Returning' THEN total_amount
				END), 2) AS returning_bundle_aov,
    ROUND(AVG(CASE
				WHEN bundle_adopted = 0 AND buyer_type = 'Returning' THEN total_amount
				END), 2) AS returning_no_bundle_aov
FROM
	full_orders
GROUP BY
	YEARWEEK(order_date)
ORDER BY
	YEARWEEK(order_date);
    
-- for every month, slice average order value (AOV) by buyer type
SELECT
	DATE_FORMAT(order_date, '%Y-%m') AS `year_month`,
    buyer_type,
    ROUND(AVG(total_amount), 2) AS aov
FROM
	full_orders
GROUP BY
	DATE_FORMAT(order_date, '%Y-%m'),
    buyer_type
ORDER BY
	DATE_FORMAT(order_date, '%Y-%m');
    
SELECT
DATE_FORMAT(order_date, '%Y-%m') AS `year_month`,
ROUND(AVG(CASE
			WHEN buyer_type = 'Guest' THEN total_amount
			END), 2) AS guest_aov,
ROUND(AVG(CASE
			WHEN buyer_type = 'New' THEN total_amount
			END), 2) AS new_aov,
ROUND(AVG(CASE
			WHEN buyer_type = 'Returning' THEN total_amount
			END), 2) AS returning_aov
FROM
	full_orders
GROUP BY
	DATE_FORMAT(order_date, '%Y-%m')
ORDER BY
	DATE_FORMAT(order_date, '%Y-%m');

-- for every month, slice average order value (AOV) by buyer type and bundle adopted
SELECT
DATE_FORMAT(order_date, '%Y-%m') AS `year_month`,
ROUND(AVG(CASE
			WHEN bundle_adopted = 1 AND buyer_type = 'Guest' THEN total_amount
			END), 2) AS guest_bundle_aov,
ROUND(AVG(CASE
			WHEN bundle_adopted = 0 AND buyer_type = 'Guest' THEN total_amount
			END), 2) AS guest_no_bundle_aov,
ROUND(AVG(CASE
			WHEN bundle_adopted = 1 AND buyer_type = 'New' THEN total_amount
			END), 2) AS new_bundle_aov,
ROUND(AVG(CASE
			WHEN bundle_adopted = 0 AND buyer_type = 'New' THEN total_amount
			END), 2) AS new_no_bundle_aov,
ROUND(AVG(CASE
			WHEN bundle_adopted = 1 AND buyer_type = 'Returning' THEN total_amount
			END), 2) AS returning_bundle_aov,
ROUND(AVG(CASE
			WHEN bundle_adopted = 0 AND buyer_type = 'Returning' THEN total_amount
			END), 2) AS returning_no_bundle_aov
FROM
	full_orders
GROUP BY
	DATE_FORMAT(order_date, '%Y-%m')
ORDER BY
	DATE_FORMAT(order_date, '%Y-%m');
    
-- for every day, slice average order value (AOV) by region
SELECT
	order_date,
    region,
    ROUND(AVG(total_amount), 2) AS aov
FROM
	full_orders
GROUP BY
	order_date,
    region
ORDER BY
	order_date;
    
SELECT
	order_date,
    ROUND(AVG(CASE
				WHEN region = 'East Coast' THEN total_amount
				END), 2) AS east_coast_aov,
    ROUND(AVG(CASE
				WHEN region = 'Midwest' THEN total_amount
				END), 2) AS midwest_aov,
    ROUND(AVG(CASE
				WHEN region = 'South' THEN total_amount
				END), 2) AS south_aov,
	ROUND(AVG(CASE
				WHEN region = 'West Coast' THEN total_amount
				END), 2) AS west_coast_aov
FROM
	full_orders
GROUP BY
	order_date
ORDER BY
	order_date;
    
-- for every week, slice average order value (AOV) by region
SELECT
	YEARWEEK(order_date) AS year_week,
    ROUND(AVG(CASE
				WHEN region = 'East Coast' THEN total_amount
				END), 2) AS east_coast_aov,
    ROUND(AVG(CASE
				WHEN region = 'Midwest' THEN total_amount
				END), 2) AS midwest_aov,
    ROUND(AVG(CASE
				WHEN region = 'South' THEN total_amount
				END), 2) AS south_aov,
	ROUND(AVG(CASE
				WHEN region = 'West Coast' THEN total_amount
				END), 2) AS west_coast_aov
FROM
	full_orders
GROUP BY
	YEARWEEK(order_date)
ORDER BY
	YEARWEEK(order_date);

-- for every month, slice average order value (AOV) by region
SELECT
	DATE_FORMAT(order_date, '%Y-%m') AS `year_month`,
    region,
    ROUND(AVG(total_amount), 2) AS aov
FROM
	full_orders
GROUP BY
	DATE_FORMAT(order_date, '%Y-%m'),
    region
ORDER BY
	DATE_FORMAT(order_date, '%Y-%m');
    
SELECT
	DATE_FORMAT(order_date, '%Y-%m') AS `year_month`,
    ROUND(AVG(CASE
				WHEN region = 'East Coast' THEN total_amount
				END), 2) AS east_coast_aov,
    ROUND(AVG(CASE
				WHEN region = 'Midwest' THEN total_amount
				END), 2) AS midwest_aov,
    ROUND(AVG(CASE
				WHEN region = 'South' THEN total_amount
				END), 2) AS south_aov,
	ROUND(AVG(CASE
				WHEN region = 'West Coast' THEN total_amount
				END), 2) AS west_coast_aov
FROM
	full_orders
GROUP BY
	DATE_FORMAT(order_date, '%Y-%m')
ORDER BY
	DATE_FORMAT(order_date, '%Y-%m');
    
-- for every day, slice aov by platform
SELECT
	order_date,
    ROUND(AVG(CASE
				WHEN platform = 'App' THEN total_amount
				END), 2) AS app_aov,
    ROUND(AVG(CASE
				WHEN platform = 'Web' THEN total_amount
				END), 2) AS web_aov
FROM
	full_orders
GROUP BY
	order_date
ORDER BY
	order_date;
    
-- for every week, slice aov by platform
SELECT
	YEARWEEK(order_date) AS year_week,
    MIN(order_date) AS week_start,
    MAX(order_date) AS week_end,
    ROUND(AVG(CASE
				WHEN platform = 'App' THEN total_amount
				END), 2) AS app_aov,
    ROUND(AVG(CASE
				WHEN platform = 'Web' THEN total_amount
				END), 2) AS web_aov
FROM
	full_orders
GROUP BY
	YEARWEEK(order_date)
ORDER BY
	YEARWEEK(order_date);
    
-- for every month, slice aov by platform
SELECT
	DATE_FORMAT(order_date, '%Y-%m') AS `year_month`,
    ROUND(AVG(CASE
				WHEN platform = 'App' THEN total_amount
				END), 2) AS app_aov,
    ROUND(AVG(CASE
				WHEN platform = 'Web' THEN total_amount
				END), 2) AS web_aov
FROM
	full_orders
GROUP BY
	DATE_FORMAT(order_date, '%Y-%m')
ORDER BY
	DATE_FORMAT(order_date, '%Y-%m');