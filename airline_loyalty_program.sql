CREATE TABLE customer_loyalty_history
(
`Loyalty_Number` MEDIUMINT UNSIGNED,
`Country` CHAR(6) DEFAULT "Canada",
`Province` VARCHAR(20), 
`City` VARCHAR(14),
`Postal_Code` CHAR(7),
`Gender` VARCHAR(6) CHECK (`Gender` IN ("Female", "Male")),
`Education` VARCHAR(20) CHECK (`Education` IN ("Bachelor", "College", "Master", "High School or Below", "Doctor")),
`Salary` MEDIUMINT UNSIGNED,
`Marital_Status` VARCHAR(8) CHECK (`Marital_Status` IN ("Married", "Divorced", "Single")),
`Loyalty_Card` VARCHAR(6),
`CLV` DECIMAL(7,2) DEFAULT NULL,
`Enrollment_Type` VARCHAR(14) CHECK (`Enrollment_Type` IN ("2018 Promotion", "Standard")),
`Enrollment_Year` SMALLINT UNSIGNED NOT NULL,
`Enrollment_Month` TINYINT UNSIGNED NOT NULL,
`Cancellation_Year` SMALLINT UNSIGNED,
`Cancellation_Month` TINYINT UNSIGNED,
PRIMARY KEY (`Loyalty_Number`)
);

CREATE TABLE customer_flight_activity 
(
`Loyalty_Number` MEDIUMINT UNSIGNED,
`Year` SMALLINT UNSIGNED,
`Month` TINYINT UNSIGNED,
`Total_Flights` TINYINT UNSIGNED,
`Distance` MEDIUMINT UNSIGNED,
`Points_Accumulated` MEDIUMINT UNSIGNED,
`Points_Redeemed` SMALLINT UNSIGNED,
`Dollar_Redeemed` TINYINT UNSIGNED,
PRIMARY KEY (`Loyalty_Number`, `Year`, `Month`),
FOREIGN KEY (`Loyalty_Number`) REFERENCES customer_loyalty_history (`Loyalty_Number`)
);

SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE
"C:\\Users\\tanik\\OneDrive - Rutgers University\\airline\\customer_loyalty_history.csv"
INTO TABLE customer_loyalty_history
COLUMNS TERMINATED BY ','
LINES TERMINATED BY '\r\n';

LOAD DATA LOCAL INFILE
"C:\\Users\\tanik\\OneDrive - Rutgers University\\airline\\customer_flight_activity.csv"
INTO TABLE customer_flight_activity
COLUMNS TERMINATED BY ','
LINES TERMINATED BY '\r\n';

UPDATE customer_loyalty_history
SET salary = null
WHERE salary = 0;

UPDATE customer_loyalty_history
SET cancellation_year = null,
cancellation_month = null
WHERE cancellation_year = 0;
---------------------------------------------------
-- checking primary keys
select count(*) from customer_flight_activity;
select count(*) from (select * from customer_flight_activity
group by Loyalty_Number, Year, Month) X;

select count(*) from customer_loyalty_history;
select count(*) from (select * from customer_loyalty_history
group by Loyalty_Number) X;

-- checking for mismatch between loyalty_numbers 
select count(distinct(loyalty_number)) from customer_flight_activity
union
select count(distinct(loyalty_number)) from customer_loyalty_history;

-- 1)
SELECT X.*, CONCAT(ROUND(Member_Count/total*100,2), '%') AS Percent_Total FROM (SELECT Loyalty_Card, CASE
WHEN Cancellation_Month IS NULL AND Cancellation_Year IS NULL THEN 'Active'
ELSE 'Cancelled' END AS 'Status', COUNT(*) AS Member_Count FROM customer_loyalty_history
GROUP BY Loyalty_Card, status) AS X
INNER JOIN (SELECT loyalty_card, COUNT(*) AS total FROM customer_loyalty_history
GROUP BY loyalty_Card) Y ON Y.Loyalty_card=X.Loyalty_card
ORDER BY Status DESC, Percent_Total DESC; 

-- 2)
SELECT Loyalty_Card, Enrollment_Type, COUNT(*) AS Member_Count FROM customer_loyalty_history
WHERE Enrollment_Year = 2018
GROUP BY Loyalty_Card, Enrollment_Type
ORDER BY enrollment_type DESC, Member_Count DESC; 

-- 3)
CREATE VIEW yearly_stats AS
(
SELECT enrollment_year AS Year, COUNT(enrollment_year) AS Number_of_Enrollments, COUNT(Cancellation_Year) AS Number_of_Cancellations FROM customer_loyalty_history
GROUP BY Enrollment_Year
ORDER BY Year
);

SELECT y1.year, y1.number_of_enrollments, 
CONCAT(ROUND(((y1.number_of_enrollments-y2.number_of_enrollments)/y2.number_of_enrollments)*100,2),'%') AS Percent_Change, 
y1.number_of_cancellations, CONCAT(ROUND(((y1.number_of_cancellations-y2.number_of_cancellations)/y2.number_of_cancellations*100),2), '%') AS Percent_Change FROM yearly_stats y1
LEFT JOIN yearly_stats y2 ON y1.year=y2.year+1;

-- 4)
WITH promotion_results AS
(
SELECT '2018 Promotion (Feb - Apr)' AS Period, COUNT(*) AS Number_of_Enrollments FROM customer_loyalty_history
WHERE Enrollment_Type = '2018 Promotion'
UNION
SELECT 'Average for Previous Years (Feb - Apr)' AS Period, ROUND(AVG(Number_of_Enrollments))AS Average_Enrollment FROM (SELECT Enrollment_Year, COUNT(*) AS Number_of_Enrollments FROM customer_loyalty_history
WHERE Enrollment_Year BETWEEN '2013' AND '2017' AND Enrollment_Month BETWEEN 2 AND 4
GROUP BY Enrollment_Year) AS X
)
SELECT p1.*, CONCAT(ROUND((p1.number_of_enrollments-p2.number_of_enrollments)/p2.number_of_enrollments*100,2),'%') AS Percent_Change FROM promotion_results p1
LEFT JOIN (SELECT * FROM promotion_results WHERE period = "Average for Previous Years (Feb - Apr)") p2 ON p1.Period != p2.Period;

-- 5)
SELECT Gender, Education, Marital_Status, CONCAT('$',FORMAT(Average_CLV,2)) AS Average_CLV FROM
(SELECT Gender, Education, Marital_Status, AVG(CLV) AS Average_CLV FROM customer_loyalty_history
GROUP BY Gender, Education, Marital_Status
ORDER BY Average_CLV DESC) AS X;

-- 6)
CREATE VIEW active_no_annual_flights AS
(
SELECT f.loyalty_number, year, sum(total_flights) AS flights FROM customer_flight_activity f
INNER JOIN customer_loyalty_history l ON l.loyalty_number=f.loyalty_number
WHERE cancellation_year IS NOT NULL
GROUP BY f.loyalty_number, year
HAVING flights = 0
);

SELECT n.loyalty_number, count(*) as years_of_inactivity
FROM active_no_annual_flights n
INNER JOIN customer_loyalty_history c ON c.loyalty_number=n.loyalty_number
WHERE enrollment_year < 2016
GROUP BY n.loyalty_number
HAVING years_of_inactivity = 2;

-- 7)
SELECT Gender, Education, Marital_Status, COUNT(*) AS Member_Count FROM (SELECT n.loyalty_number, gender, education, marital_status
FROM active_no_annual_flights n
INNER JOIN customer_loyalty_history c ON c.loyalty_number=n.loyalty_number
WHERE enrollment_year < 2016
GROUP BY n.loyalty_number, gender, education, marital_status
HAVING count(*) = 2) AS X
GROUP BY Gender, Education, Marital_Status
ORDER BY Member_Count DESC;