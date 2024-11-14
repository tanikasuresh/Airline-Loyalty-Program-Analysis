### The following data is Customer Loyalty Program from Northern Lights Air, a fictional airline based in Canada. The company held a promotion to improve program enrollment from February to April of 2018.
#

The following Entity Relationship Diagram visualizes the tables and attributes in the data:
![Screenshot (56)](https://github.com/user-attachments/assets/7ab8c6c3-12c0-45e9-8151-c5bece0eb98d)

The following is a Tableau dashboard to summarize the data

![Screenshot (57)](https://github.com/user-attachments/assets/6ddede46-4c57-4812-9d9c-17b6168566e3)

Here, we see that the 2018 Promotion that took place from February to April caused enrollment to skyrocket during those months. If we take a closer look at the numbers, there were 971 enrollments during the promotion period. The average number of enrollments during this same time frame (February to April) in the last five years was 587. Therefore, the 2018 Promotion increased enrollment by about **~65%**. Looking at the annual enrollments, we see that there were 3,010 enrollments in 2018, which is a **~21.03%** increase from the previous year. Adding on, 2018 had the biggest increase in program enrollment in the past five years, due to the 2018 Promotion.

Other key findings relate to program cancellation. We can calculate how long each member was enrolled in the program before cancelling. It is evident that the most number of members **cancelled within the first two years** of enrolling. Most notably, the second greatest number of members cancelled before completing a year of enrollment.

Adding on, the two demographic groups that had the most number of cancellations were married women with a Bachelor's degree and married men with a Bachelor's degree. Further research would have to be done, but it would seem that being married and with a Bachelor's would indicate that members are not flying as often due to domestic and work committments and therefore do not benefit from an airline loyalty program.

## Analyzing the Data with SQL

1) What are the number of Active and Former members for each membership type within the Loyalty Program? 
```sql
SELECT X.*, CONCAT(ROUND(Member_Count/total*100,2), '%') AS Percent_Total FROM (SELECT Loyalty_Card, CASE
WHEN Cancellation_Month IS NULL AND Cancellation_Year IS NULL THEN 'Active'
ELSE 'Cancelled' END AS 'Status', COUNT(*) AS Member_Count FROM customer_loyalty_history
GROUP BY Loyalty_Card, status) AS X
INNER JOIN (SELECT loyalty_card, COUNT(*) AS total FROM customer_loyalty_history
GROUP BY loyalty_Card) Y ON Y.Loyalty_card=X.Loyalty_card
ORDER BY Status DESC, Percent_Total DESC; 
```
The query results show that the Star Loyalty Card has the most Active members within the loyalty program, but it also has the highest number of cancellations.

2) What are the number of members (both Active and Former) that enrolled in the Loyalty Program under the Standard Enrollment or during the 2018 Promotion for each membership type?
```sql
SELECT Loyalty_Card, Enrollment_Type, COUNT(*) AS Member_Count FROM customer_loyalty_history
WHERE Enrollment_Year = 2018
GROUP BY Loyalty_Card, Enrollment_Type
ORDER BY Member_Count DESC;
```

3) What are the number of enrollments and cancellations for each year?
```sql
SELECT enrollment_year AS Year, COUNT(enrollment_year) AS Number_of_Enrollments,
COUNT(Cancellation_Year) AS Number_of_Cancellations FROM customer_loyalty_history
GROUP BY Enrollment_Year
ORDER BY Year;
```

4) What was the number of enrollments during the 2018 Promotion Period and how did it differ from the number of enrollments during the same months in previous years?
```sql
SELECT '2018 Promotion (Feb - Apr)' AS Period, COUNT(*) AS Number_of_Enrollments
FROM customer_loyalty_history
WHERE Enrollment_Type = '2018 Promotion'
UNION
SELECT 'Average for Previous Years (Feb - Apr)' AS Period, ROUND(AVG(Number_of_Enrollments))
AS Average_Enrollment
FROM (SELECT Enrollment_Year, COUNT(*) AS Number_of_Enrollments FROM customer_loyalty_history
WHERE Enrollment_Year BETWEEN '2013' AND '2017' AND Enrollment_Month BETWEEN 2 AND 4
GROUP BY Enrollment_Year) AS X;
```

5) What is the average Customer Lifetime Value for different combinations of demographics (Gender, Education, Marital Status)?
```sql
SELECT Gender, Education, Marital_Status, CONCAT('$',FORMAT(Average_CLV,2)) AS Average_CLV FROM
(SELECT Gender, Education, Marital_Status, AVG(CLV) AS Average_CLV FROM customer_loyalty_history
GROUP BY Gender, Education, Marital_Status
ORDER BY Average_CLV DESC) AS X;
```

6) What is the average number of flights for each combination of demographics (Gender, Education, Marital Status)?
```sql
SELECT Gender, Education, Marital_Status, ROUND(AVG(Total_Flights)) AS Average_Flights
FROM (SELECT f.Loyalty_Number,Gender, Education, Marital_Status, SUM(Total_Flights) AS Total_Flights
FROM customer_flight_activity f
INNER JOIN customer_loyalty_history l ON f.Loyalty_Number=l.Loyalty_Number
GROUP BY f.Loyalty_Number, Gender, Education, Marital_Status) AS X
GROUP BY Gender, Education, Marital_Status
ORDER BY Average_Flights DESC;
```

7) Of the members who cancelled their enrollment, how many and how long were the former members in the program?
```sql
WITH cancelled_members AS
(
SELECT * FROM customer_loyalty_history
WHERE cancellation_year IS NOT NULL AND cancellation_month IS NOT NULL
)
SELECT cancellation_year - enrollment_year AS Years_Enrolled, count(*) AS Member_Count
FROM cancelled_members
GROUP BY Years_Enrolled
ORDER BY Member_Count DESC;
```

8) How many members joined prior to 2017 but have not booked any flights in 2017 and 2018?
```sql
WITH active_no_annual_flights AS
(
SELECT f.loyalty_number, year, sum(total_flights) AS flights
FROM customer_flight_activity f
INNER JOIN customer_loyalty_history l ON l.loyalty_number=f.loyalty_number
WHERE cancellation_year IS NOT NULL
GROUP BY f.loyalty_number, year
HAVING flights = 0
)
SELECT COUNT(*) AS Member_Count FROM (SELECT n.loyalty_number, count(*) as years_of_inactivity
FROM active_no_annual_flights n
INNER JOIN customer_loyalty_history c ON c.loyalty_number=n.loyalty_number
WHERE enrollment_year < 2017
GROUP BY n.loyalty_number
HAVING years_of_inactivity = 2) AS X;
```
