CREATE TABLE clinics (
    clinic_id TEXT PRIMARY KEY,
    clinic_name TEXT,
    city TEXT,
    state TEXT
);

CREATE TABLE patients (
    patient_id TEXT PRIMARY KEY,
    patient_name TEXT,
    city TEXT,
    state TEXT
);

CREATE TABLE appointments (
    appointment_id TEXT PRIMARY KEY,
    clinic_id TEXT,
    patient_id TEXT,
    appointment_date TEXT,
    sales_channel TEXT,
    FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id)
);

CREATE TABLE billing (
    bill_id TEXT PRIMARY KEY,
    appointment_id TEXT,
    bill_date TEXT,
    amount REAL,
    FOREIGN KEY (appointment_id) REFERENCES appointments(appointment_id)
);

CREATE TABLE expenses (
    expense_id TEXT PRIMARY KEY,
    clinic_id TEXT,
    expense_date TEXT,
    expense_amount REAL,
    FOREIGN KEY (clinic_id) REFERENCES clinics(clinic_id)
);


INSERT INTO clinics VALUES
('CL001','City Health Clinic','Hyderabad','Telangana'),
('CL002','Sunrise Clinic','Hyderabad','Telangana'),
('CL003','Care Plus Clinic','Vijayawada','Andhra Pradesh'),
('CL004','LifeCare Clinic','Guntur','Andhra Pradesh'),
('CL005','Metro Clinic','Vijayawada','Andhra Pradesh');

INSERT INTO patients VALUES
('P001','Ramesh','Hyderabad','Telangana'),
('P002','Suresh','Vijayawada','Andhra Pradesh'),
('P003','Anil','Guntur','Andhra Pradesh'),
('P004','Kiran','Hyderabad','Telangana'),
('P005','Rahul','Vijayawada','Andhra Pradesh'),
('P006','Mahesh','Guntur','Andhra Pradesh'),
('P007','Vijay','Hyderabad','Telangana'),
('P008','Arun','Vijayawada','Andhra Pradesh');

INSERT INTO appointments VALUES
('A001','CL001','P001','2021-01-10','Online'),
('A002','CL002','P002','2021-02-12','Walk-in'),
('A003','CL003','P003','2021-03-15','Online'),
('A004','CL004','P004','2021-03-20','Referral'),
('A005','CL005','P005','2021-04-05','Online'),
('A006','CL001','P006','2021-05-18','Walk-in'),
('A007','CL002','P007','2021-06-21','Online'),
('A008','CL003','P008','2021-07-30','Referral'),
('A009','CL004','P001','2021-08-10','Online'),
('A010','CL005','P002','2021-09-15','Walk-in');

INSERT INTO billing VALUES
('B001','A001','2021-01-10',1500),
('B002','A002','2021-02-12',1800),
('B003','A003','2021-03-15',2200),
('B004','A004','2021-03-20',1700),
('B005','A005','2021-04-05',2500),
('B006','A006','2021-05-18',1900),
('B007','A007','2021-06-21',3000),
('B008','A008','2021-07-30',2700),
('B009','A009','2021-08-10',2100),
('B010','A010','2021-09-15',2600);

INSERT INTO expenses VALUES
('E001','CL001','2021-01-01',800),
('E002','CL002','2021-02-01',900),
('E003','CL003','2021-03-01',700),
('E004','CL004','2021-03-01',1000),
('E005','CL005','2021-04-01',850),
('E006','CL001','2021-05-01',950),
('E007','CL002','2021-06-01',750),
('E008','CL003','2021-07-01',1100),
('E009','CL004','2021-08-01',900),
('E010','CL005','2021-09-01',1000);

1. Find the revenue we got from each sales channel in a given year
SELECT 
    a.sales_channel,
    SUM(b.amount) AS total_revenue
FROM appointments a
JOIN billing b
ON a.appointment_id = b.appointment_id
WHERE strftime('%Y', b.bill_date) = '2021'
GROUP BY a.sales_channel
ORDER BY total_revenue DESC;

2. Find top 10 the most valuable customers for a given year
SELECT 
    a.patient_id,
    SUM(b.amount) AS total_spent
FROM appointments a
JOIN billing b
ON a.appointment_id = b.appointment_id
WHERE strftime('%Y', b.bill_date) = '2021'
GROUP BY a.patient_id
ORDER BY total_spent DESC
LIMIT 10;

3. Find month wise revenue, expense, profit , status (profitable / not-profitable) for a given year
WITH revenue_data AS (
    SELECT
        strftime('%m', bill_date) AS month,
        SUM(amount) AS revenue
    FROM billing
    WHERE strftime('%Y', bill_date) = '2021'
    GROUP BY strftime('%m', bill_date)
),

expense_data AS (
    SELECT
        strftime('%m', expense_date) AS month,
        SUM(expense_amount) AS expense
    FROM expenses
    WHERE strftime('%Y', expense_date) = '2021'
    GROUP BY strftime('%m', expense_date)
)

SELECT
    r.month,
    r.revenue,
    e.expense,
    (r.revenue - e.expense) AS profit,

    CASE
        WHEN (r.revenue - e.expense) > 0 
        THEN 'Profitable'
        ELSE 'Not-Profitable'
    END AS status

FROM revenue_data r
JOIN expense_data e
ON r.month = e.month
ORDER BY r.month;

4. For each city find the most profitable clinic for a given month
WITH clinic_profit AS (

SELECT
    c.city,
    c.clinic_id,

    SUM(b.amount)
    - IFNULL(SUM(e.expense_amount),0) 
    AS profit

FROM clinics c

JOIN appointments a
ON c.clinic_id = a.clinic_id

JOIN billing b
ON a.appointment_id = b.appointment_id

LEFT JOIN expenses e
ON c.clinic_id = e.clinic_id
AND strftime('%m', e.expense_date) = '03'
AND strftime('%Y', e.expense_date) = '2021'

WHERE strftime('%m', b.bill_date) = '03'
AND strftime('%Y', b.bill_date) = '2021'

GROUP BY c.city, c.clinic_id

),

ranked AS (

SELECT *,
       RANK() OVER (
           PARTITION BY city
           ORDER BY profit DESC
       ) AS rnk

FROM clinic_profit

)

SELECT city, clinic_id, profit
FROM ranked
WHERE rnk = 1;

5. For each state find the second least profitable clinic for a given month
WITH clinic_profit AS (

SELECT
    c.state,
    c.clinic_id,

    SUM(b.amount)
    - IFNULL(SUM(e.expense_amount),0) 
    AS profit

FROM clinics c

JOIN appointments a
ON c.clinic_id = a.clinic_id

JOIN billing b
ON a.appointment_id = b.appointment_id

LEFT JOIN expenses e
ON c.clinic_id = e.clinic_id
AND strftime('%m', e.expense_date) = '03'
AND strftime('%Y', e.expense_date) = '2021'

WHERE strftime('%m', b.bill_date) = '03'
AND strftime('%Y', b.bill_date) = '2021'

GROUP BY c.state, c.clinic_id

),

ranked AS (

SELECT *,
       DENSE_RANK() OVER (
           PARTITION BY state
           ORDER BY profit ASC
       ) AS rnk

FROM clinic_profit

)

SELECT state, clinic_id, profit
FROM ranked
WHERE rnk = 2;