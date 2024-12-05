### The following data is the Customer Loyalty Program from Northern Lights Air, a fictional airline based in Canada. The company held a promotion to improve program enrollment from February to April of 2018.
#
The following is a Tableau dashboard to summarize the data
<br /><br />
![Screenshot (57)](https://github.com/user-attachments/assets/6ddede46-4c57-4812-9d9c-17b6168566e3)
<br /><br />
Here, we see that the 2018 Promotion that took place from February to April caused enrollment to skyrocket during those months. If we take a closer look at the numbers, there were 971 enrollments during the promotion period. The average number of enrollments during this same time frame (February to April) in the last five years was 587. Therefore, the 2018 Promotion increased enrollment by about **~65%**. Looking at the annual enrollments, we see that there were 3,010 enrollments in 2018, which is a **~21.03%** increase from the previous year. Adding on, 2018 had the biggest increase in program enrollment in the past five years, due to the 2018 Promotion.
<br /><br />
Other key findings relate to program cancellation. We can calculate how long each member was enrolled in the program before canceling. It is evident that the most number of members **canceled within the first two years** of enrolling. Most notably, the second-greatest number of members canceled before completing a year of enrollment.
<br /><br />
Adding on, the two demographic groups that had the most number of cancellations were married women with a Bachelor's degree and married men with a Bachelor's degree. Further research would have to be done, but it would seem that being married and with a Bachelor's would indicate that members are not flying as often due to domestic and work commitments and therefore do not benefit from an airline loyalty program.
<br /><br />
## Analyzing the Data with SQL

The following Entity Relationship Diagram visualizes the tables and attributes in the data:
<br /><br />
<img src = "https://github.com/user-attachments/assets/7ab8c6c3-12c0-45e9-8151-c5bece0eb98d" width = '450'>
<br /><br />

1) What is the number of Active and Former members for each membership type within the Loyalty Program?
<br /><br />
```sql
SELECT X.*, CONCAT(ROUND(Member_Count/total*100,2), '%') AS Percent_Total FROM (SELECT Loyalty_Card,
CASE WHEN Cancellation_Month IS NULL AND Cancellation_Year IS NULL THEN 'Active'
ELSE 'Cancelled' END AS 'Status', COUNT(*) AS Member_Count FROM customer_loyalty_history
GROUP BY Loyalty_Card, status) AS X
INNER JOIN (SELECT loyalty_card, COUNT(*) AS total FROM customer_loyalty_history
GROUP BY loyalty_Card) Y ON Y.Loyalty_card=X.Loyalty_card
ORDER BY Status DESC, Percent_Total DESC; 
```
<img src = "https://github.com/user-attachments/assets/de249a82-a753-4afc-82d9-96019a727be3" width = '350'>

<br /><br />
The query results show that among all types of Loyalty Cards available in the program, the Aurora Card has the highest percentage of cancellations, with approximately ~13% of all Aurora members having canceled their membership. However, this percentage is not cause for concern as it is similar to the cancellation percentages for other Loyalty Cards. It is evident that all Loyalty Cards have about 90% active enrollment and 10% cancellation status. 
#

2) What is the number of members who enrolled in the Loyalty Program in 2018 under the Standard Enrollment or during the 2018 Promotion for each membership type?
<br /><br />
```sql
SELECT Loyalty_Card, Enrollment_Type, COUNT(*) AS Member_Count FROM customer_loyalty_history
WHERE Enrollment_Year = 2018
GROUP BY Loyalty_Card, Enrollment_Type
ORDER BY Enrollment_Type DESC, Member_Count DESC;
```
<img src = "https://github.com/user-attachments/assets/1bbc13c3-bd10-4b7d-95a5-387194cdabd0" width = '350'>
<br /><br />
Here, we see that in 2018, the largest number of people who enrolled outside of and during the 2018 Promotion was for the Star Loyalty Card. On the other hand, the Aurora Loyalty Card had the least number of signups in both the regular year and the 2018 promotion period. I would recommend promoting the Aurora Loyalty Card with a similar campaign to increase member enrollment.

#
3) What are the number of enrollments and cancellations for each year?
<br /><br />
```sql
CREATE VIEW yearly_stats AS
(
SELECT enrollment_year AS Year, COUNT(enrollment_year) AS Number_of_Enrollments, COUNT(Cancellation_Year) AS Number_of_Cancellations
FROM customer_loyalty_history
GROUP BY Enrollment_Year
ORDER BY Year
);

SELECT y1.year, y1.number_of_enrollments, 
CONCAT(ROUND(((y1.number_of_enrollments-y2.number_of_enrollments)/y2.number_of_enrollments)*100,2),'%') AS Percent_Change, 
y1.number_of_cancellations,
CONCAT(ROUND(((y1.number_of_cancellations-y2.number_of_cancellations)/y2.number_of_cancellations*100),2), '%') AS Percent_Change
FROM yearly_stats y1
LEFT JOIN yearly_stats y2 ON y1.year=y2.year+1;

```
<img src = "https://github.com/user-attachments/assets/16aae529-b712-4070-bb66-9a16ef16c146" width = '550'>

<br /><br />
The query results show that annual enrollments have increased the most during 2018 in the past five years and that annual cancellations have continued to decrease in the past three years. Most notably, the rate of decrease is actually increasing, meaning that there have been fewer and fewer cancellations per year since 2016. To summarize, 2018 saw the largest number of enrollments and the smallest amount of cancellations.  
#
4) What was the number of enrollments during the 2018 Promotion Period and how did it differ from the number of enrollments during the same months in previous years?
<br /><br />
```sql
WITH promotion_results AS
(
SELECT '2018 Promotion (Feb - Apr)' AS Period, COUNT(*) AS Number_of_Enrollments FROM customer_loyalty_history
WHERE Enrollment_Type = '2018 Promotion'
UNION
SELECT 'Average for Previous Years (Feb - Apr)' AS Period, ROUND(AVG(Number_of_Enrollments))AS Average_Enrollment
FROM (SELECT Enrollment_Year, COUNT(*) AS Number_of_Enrollments
FROM customer_loyalty_history
WHERE Enrollment_Year BETWEEN '2013' AND '2017' AND Enrollment_Month BETWEEN 2 AND 4
GROUP BY Enrollment_Year) AS X
)
SELECT p1.*, CONCAT(ROUND((p1.number_of_enrollments-p2.number_of_enrollments)/p2.number_of_enrollments*100,2),'%') AS Percent_Change
FROM promotion_results p1
LEFT JOIN (SELECT * FROM promotion_results WHERE period = "Average for Previous Years (Feb - Apr)") p2
ON p1.Period != p2.Period;
```
<img src = "https://github.com/user-attachments/assets/c5740a0a-9876-4fe1-a3e0-9a0d42752152" width = '550'>

<br /><br />
Here, we can quantify the results of the 2018 Promotion from February to April. We see that there were 971 program enrollments during this period. We can also calculate that the average number of program enrollments from February to April in the past five years was 587. Therefore, the 2018 promotion boosted program enrollment from February to April by **~65% **.
#
5) What is the average Customer Lifetime Value for different combinations of demographics (Gender, Education, Marital Status)?
<br /><br />
```sql
SELECT Gender, Education, Marital_Status, CONCAT('$',FORMAT(Average_CLV,2)) AS Average_CLV FROM
(SELECT Gender, Education, Marital_Status, AVG(CLV) AS Average_CLV FROM customer_loyalty_history
GROUP BY Gender, Education, Marital_Status
ORDER BY Average_CLV DESC) AS X;
```

<img src = "https://github.com/user-attachments/assets/6cadb960-31a9-4c55-86fa-128ccc642bc0" width = '450'>
.................................................................................................................................................................
<img src = "https://github.com/user-attachments/assets/30d89ab4-2a7c-4267-85ca-d544416ab856" width = '450'>

<br /><br />
The following images show the top 5 and the bottom 5 results. From this, we can see that the customer demographic group that has the highest average Customer Lifetime Value is divorced men with, at most, a high school education. On the other hand, the customer demographics that have the least average CLV are single women with, at most, a high school education.

#
6) How many members joined prior to 2017 but have not booked any flights in 2017 and 2018?
<br /><br />
```sql
CREATE VIEW active_no_annual_flights AS
(
SELECT f.loyalty_number, year, sum(total_flights) AS flights
FROM customer_flight_activity f
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
```

```
Member_Count
824
```
<br /><br />
The following query identifies active members who have had no flight activity in 2017 and 2018 but joined prior to 2016, indicating that they have been members for at least a year by January 2017. These customers should be classified as inactive, and marketing efforts, including emails and special offers, should be made to re-engage these customers.
#

7) What are the most prominent demographics of Active members who are inactive?
<br /><br />

```sql
SELECT Gender, Education, Marital_Status, COUNT(*) AS Member_Count
FROM (SELECT n.loyalty_number, gender, education, marital_status
FROM active_no_annual_flights n
INNER JOIN customer_loyalty_history c ON c.loyalty_number=n.loyalty_number
WHERE enrollment_year < 2016
GROUP BY n.loyalty_number, gender, education, marital_status
HAVING count(*) = 2) AS X
GROUP BY Gender, Education, Marital_Status
ORDER BY Member_Count DESC;
```

<img src = "https://github.com/user-attachments/assets/b33081a6-41c7-4492-b730-9944542745f8" width = '450'>

<br /><br />
Here, we see that married men and women with a bachelor's degree are primarily active members but have been inactive for the past two years. If you recall from the Tableau dashboard, these are the same two demographics that had the most cancellations among them. It seems that it is common for married men and women with a college education to either continue their membership but not book any flights or cancel their membership for the loyalty program. Either way, it seems that there are a lot of missed opportunities within these demographics, so it is worth targeting marketing efforts to increase activity and prevent cancellations. 
#

## Notable Findings 
- The number of enrollments in 2018 increased by ~21.03% from the previous year
- The 2018 Promotion increased enrollment between February to April by ~65% compared to the average of previous years
- The largest number of members who canceled their membership did so within the first two years of joining
- There are 824 active members who had no flight activity in 2017 and 2018
- The two most prominent groups that are inactive are married men and women with a college education
