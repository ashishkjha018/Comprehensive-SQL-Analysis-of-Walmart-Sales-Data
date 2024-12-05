use internshaala_course;
SELECT * FROM walmartsales

-- Task 1 (Top Branch by Sales Growth Rate) --

WITH SalesGrowth AS (
    SELECT 
        Branch,
        DATE_FORMAT(STR_TO_DATE(Date, '%d-%m-%Y'), '%Y-%m') AS Month,
        SUM(Total) AS TotalSales,
        LAG(SUM(Total)) OVER (PARTITION BY Branch ORDER BY DATE_FORMAT(STR_TO_DATE(Date, '%d-%m-%Y'), '%Y-%m')) AS PreviousMonthSales
    FROM 
        walmartsales
    GROUP BY 
        Branch, DATE_FORMAT(STR_TO_DATE(Date, '%d-%m-%Y'), '%Y-%m')
)
SELECT 
    Branch,
    ROUND(MAX(
        CASE 
            WHEN PreviousMonthSales IS NOT NULL AND PreviousMonthSales > 0 THEN 
                (TotalSales - PreviousMonthSales) * 100.0 / PreviousMonthSales
            ELSE 0
        END
    ), 2) AS MaxGrowthRate
FROM 
    SalesGrowth
GROUP BY 
    Branch
ORDER BY 
    MaxGrowthRate DESC
LIMIT 1;

-- Task 2 (Most Profitable Product Line for Each Branch) --

WITH RankedProductLines AS (
    SELECT Branch, `Product line`, `gross income`,
        RANK() OVER (PARTITION BY Branch ORDER BY `gross income` DESC) AS Ranked
    FROM 
        WalmartSales
)
SELECT 
    Branch, `Product line`, `gross income`
FROM 
    RankedProductLines
WHERE 
    Ranked = 1;
    
-- Task 3 (Customer Segmentation Based on Spending) --

WITH CustomerSpending AS (
    SELECT `Customer ID`, `Customer type`, ROUND(SUM(Total),2) AS Total_Spent
    FROM WalmartSales
    GROUP BY `Customer ID`, `Customer type`
),
CustomerClassification AS (
    SELECT `Customer ID`, `Customer type`, Total_Spent,
        CASE 
            WHEN Total_Spent >= (SELECT MAX(Total_Spent) * 0.66 FROM CustomerSpending) THEN 'High'
            WHEN Total_Spent >= (SELECT MAX(Total_Spent) * 0.33 FROM CustomerSpending) THEN 'Medium'
            ELSE 'Low'
        END AS Spending_Tier
    FROM  CustomerSpending
)
SELECT `Customer ID`, `Customer type`, Total_Spent, Spending_Tier
FROM CustomerClassification
ORDER BY `Customer ID` ASC;

-- Task 4 (Detecting Anomalies in Sales Transactions) --

SELECT AVG(Total) AS Average_Total, STDDEV(Total) AS Standard_Deviation
FROM WalmartSales;
    
SELECT `Invoice ID`, `Product line`, Total
FROM WalmartSales
WHERE 
    Total > (SELECT AVG(Total) + 2 * STDDEV(Total) FROM WalmartSales) -- Sales above 2 std dev
    OR Total < 85
ORDER BY Total DESC;

-- Task 5 (Most Popular Payment Method by City) --

SELECT City, Payment, Payment_Count
FROM (
    SELECT City, Payment,
        COUNT(*) AS Payment_Count,
        MAX(COUNT(*)) OVER (PARTITION BY City) AS Max_Count
    FROM WalmartSales
    GROUP BY City, Payment
) AS Subquery
WHERE Payment_Count = Max_Count
ORDER BY City;

-- Task 6 (Monthly Sales Distribution by Gender) --

SELECT 
    DATE_FORMAT(STR_TO_DATE(Date, '%d-%m-%Y'), '%M') AS MONTHNAME,
    Gender,
    ROUND(SUM(Total),2) AS Total_Sales
FROM WalmartSales
GROUP BY 
    DATE_FORMAT(STR_TO_DATE(Date, '%d-%m-%Y'), '%M'), 
    Gender
ORDER BY 
	FIELD(MONTHNAME,'January','February','March'), 
	Gender;

-- Task 7 (Best Product Line by Customer Type) --

SELECT ws.`Customer type`,
    ws.`Product line`,
    ROUND(SUM(ws.Total),2) AS Total_Sales
FROM WalmartSales ws
GROUP BY ws.`Customer type`, ws.`Product line`
HAVING 
    SUM(ws.Total) = (
        SELECT MAX(Product_Line_Sales)
        FROM (
            SELECT SUM(Total) AS Product_Line_Sales
            FROM WalmartSales
            WHERE `Customer type` = ws.`Customer type`
            GROUP BY `Product line`
        ) AS MaxSales
    )
ORDER BY
	ws.`Customer type`;
    
-- Task 8 (Identifying Repeat Customers) --

SELECT 
    w1.`Customer ID`,
    MIN(STR_TO_DATE(w1.Date, '%d-%m-%Y')) AS First_Purchase,
    MAX(STR_TO_DATE(w2.Date, '%d-%m-%Y')) AS Last_Purchase,
    (COUNT(DISTINCT w2.`Invoice ID`) + 1) AS Total_Repeat_Buys 
FROM
	walmartsales w1
JOIN 
    walmartsales w2 ON w1.`Customer ID` = w2.`Customer ID`
WHERE 
    STR_TO_DATE(w1.Date, '%d-%m-%Y') < STR_TO_DATE(w2.Date, '%d-%m-%Y')
    AND
    STR_TO_DATE(w2.Date, '%d-%m-%Y') BETWEEN '2019-01-01' AND '2019-02-01'
GROUP BY 
	w1.`Customer ID` -- necessary because we have aggregate function in query
ORDER BY
	w1.`Customer ID`;
    
-- Task 9 (Top 5 Customers by Sales Volume) --

SELECT 
    `Customer ID`,
    ROUND(SUM(Total),2) AS Total_Revenue
FROM 
    walmartsales
GROUP BY 
    `Customer ID`
ORDER BY 
    Total_Revenue DESC
LIMIT 5;

-- Task 10 (Sales Trends by Day of the Week) --

SELECT 
    DAYNAME(STR_TO_DATE(Date, '%d-%m-%Y')) AS Day_of_Week,
    ROUND(SUM(Total),2) AS Total_Sales
FROM 
    walmartsales
GROUP BY 
    DAYNAME(STR_TO_DATE(Date, '%d-%m-%Y'))
ORDER BY 
    Total_Sales DESC;