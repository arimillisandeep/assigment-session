CREATE TABLE users (
    user_id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100),
    phone_number VARCHAR(15),
    mail_id VARCHAR(100),
    billing_address VARCHAR(200)
);

CREATE TABLE bookings (
    booking_id VARCHAR(50) PRIMARY KEY,
    booking_date TIMESTAMP,
    room_no VARCHAR(50),
    user_id VARCHAR(50),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE items (
    item_id VARCHAR(50) PRIMARY KEY,
    item_name VARCHAR(100),
    item_rate DECIMAL(10,2)
);

CREATE TABLE booking_commercials (
    id VARCHAR(50) PRIMARY KEY,
    booking_id VARCHAR(50),
    bill_id VARCHAR(50),
    bill_date TIMESTAMP,
    item_id VARCHAR(50),
    item_quantity DECIMAL(10,2),
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
    FOREIGN KEY (item_id) REFERENCES items(item_id)
);


INSERT INTO users VALUES
('21wrcxuy-67erfn','John Doe','9799999999','john.doe@example.com','Street Y'),
('31abcxuy-88abcd','Rahul Kumar','9898989898','rahul@example.com','Street Z');

INSERT INTO bookings VALUES
('bk-001','2021-10-15 10:30:00','rm-101','21wrcxuy-67erfn'),
('bk-002','2021-11-10 12:00:00','rm-102','21wrcxuy-67erfn'),
('bk-003','2021-11-18 09:15:00','rm-103','31abcxuy-88abcd');

INSERT INTO items VALUES
('itm-001','Tawa Paratha',18),
('itm-002','Mix Veg',89),
('itm-003','Paneer Butter Masala',150);

INSERT INTO booking_commercials VALUES
('id-001','bk-001','bill-001','2021-10-15 11:00:00','itm-001',3),
('id-002','bk-002','bill-002','2021-11-10 13:00:00','itm-002',2),
('id-003','bk-002','bill-002','2021-11-10 13:00:00','itm-003',1),
('id-004','bk-003','bill-003','2021-11-18 10:00:00','itm-002',5); 


1. For every user in the system, get the user_id and last booked room_no
SELECT user_id, room_no
FROM (
    SELECT 
        user_id,
        room_no,
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY booking_date DESC
        ) AS rn
    FROM bookings
)
WHERE rn = 1;

2. Get booking_id and total billing amount of every booking created in November, 2021
SELECT 
    bc.booking_id,
    SUM(i.item_rate * bc.item_quantity) AS total_billing_amount
FROM booking_commercials bc
JOIN items i
ON bc.item_id = i.item_id
WHERE strftime('%m', bc.bill_date) = '11'
AND strftime('%Y', bc.bill_date) = '2021'
GROUP BY bc.booking_id;

3. Get bill_id and bill amount of all the bills raised in October, 2021 having bill amount >1000
SELECT 
    bc.bill_id,
    SUM(i.item_rate * bc.item_quantity) AS bill_amount
FROM booking_commercials bc
JOIN items i
ON bc.item_id = i.item_id
WHERE strftime('%m', bc.bill_date) = '10'
AND strftime('%Y', bc.bill_date) = '2021'
GROUP BY bc.bill_id
HAVING SUM(i.item_rate * bc.item_quantity) > 1000;

4. Determine the most ordered and least ordered item of each month of year 2021
WITH item_counts AS (
    SELECT
        strftime('%m', bc.bill_date) AS month,
        bc.item_id,
        SUM(bc.item_quantity) AS total_qty
    FROM booking_commercials bc
    WHERE strftime('%Y', bc.bill_date) = '2021'
    GROUP BY 
        strftime('%m', bc.bill_date),
        bc.item_id
),

ranked_items AS (
    SELECT *,
        RANK() OVER (
            PARTITION BY month
            ORDER BY total_qty DESC
        ) AS most_rank,

        RANK() OVER (
            PARTITION BY month
            ORDER BY total_qty ASC
        ) AS least_rank
    FROM item_counts
)

SELECT
    month,
    item_id,
    total_qty,
    CASE
        WHEN most_rank = 1 THEN 'Most Ordered'
        WHEN least_rank = 1 THEN 'Least Ordered'
    END AS order_type
FROM ranked_items
WHERE most_rank = 1
OR least_rank = 1
ORDER BY month;

5. Find the customers with the second highest bill value of each month of year 2021
WITH monthly_bills AS (
    SELECT
        strftime('%m', bc.bill_date) AS month,
        b.user_id,
        bc.bill_id,
        SUM(i.item_rate * bc.item_quantity) AS bill_amount
    FROM booking_commercials bc
    JOIN bookings b
        ON bc.booking_id = b.booking_id
    JOIN items i
        ON bc.item_id = i.item_id
    WHERE strftime('%Y', bc.bill_date) = '2021'
    GROUP BY
        strftime('%m', bc.bill_date),
        b.user_id,
        bc.bill_id
),

ranked_bills AS (
    SELECT *,
        DENSE_RANK() OVER (
            PARTITION BY month
            ORDER BY bill_amount DESC
        ) AS rnk
    FROM monthly_bills
)

SELECT
    month,
    user_id,
    bill_id,
    bill_amount
FROM ranked_bills
WHERE rnk = 2
ORDER BY month;