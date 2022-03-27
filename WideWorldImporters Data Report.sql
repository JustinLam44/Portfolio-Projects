/*
WideWorldImporters Database Exploration
Skills used: Aggregate, Analytic, Ranking, Conversion , Date & Time Functions, Expressions, Views
Source: https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
*/

--#1 Querying Top 10 past due customers alongside past due balance & oldest past due invoice
WITH [AR Data] AS 
(
SELECT
[CustomerID]
,SUM(TransactionAmount) AS [Account Balance]
,MIN([TransactionDate]) AS [Oldest Past Due Invoice]

FROM [WideWorldImporters].[Sales].[CustomerTransactions]
WHERE [OutstandingBalance] <> 0
GROUP BY [CustomerID]
)

SELECT TOP (10)
[CustomerName]
,[Account Balance]
,FORMAT ([Oldest Past Due Invoice], 'dd MMM yyyy') AS [Oldest Past Due Invoice]

FROM [AR Data] 
JOIN [WideWorldImporters].[Sales].[Customers] on [AR Data].[CustomerID]=[WideWorldImporters].[Sales].[Customers].[CustomerID]
ORDER BY [Account Balance] DESC;

--#2 Querying top 10 customers of all time alongside total order amounts, # of orders, avg order amount, and % of all time sales they account for
WITH [Customer History] AS 
(
SELECT
[CustomerID]
,SUM(TransactionAmount) AS [Total Invoiced Amount]
,SUM(CASE WHEN TransactionAmount > 0 THEN 1 ELSE 0 END) AS [Number of Orders]
,CAST(ROUND(AVG(TransactionAmount),0) as INT) AS [Average Order Amount]

FROM [WideWorldImporters].[Sales].[CustomerTransactions]
WHERE [InvoiceID] IS NOT NULL
GROUP BY [CustomerID]
)

SELECT TOP (10)
[CustomerName]
,[Total Invoiced Amount]
,[Number of Orders]
,[Average Order Amount]
,[Total Invoiced Amount]/(SELECT SUM([Total Invoiced Amount]) FROM [Customer History] AS A) AS [% of Total Invoiced Amount]

FROM [Customer History] 
JOIN [WideWorldImporters].[Sales].[Customers] on [Customer History].[CustomerID]=[WideWorldImporters].[Sales].[Customers].[CustomerID]
ORDER BY [Total Invoiced Amount] DESC;

--#3 Querying Customer Category Sales for Year 2015 & 2016 

SELECT
[CustomerCategoryName]
,SUM(TransactionAmount) AS [Total Invoiced Amount]
,SUM(TransactionAmount) / (SELECT SUM(TransactionAmount) FROM [WideWorldImporters].[Sales].[CustomerTransactions] WHERE [InvoiceID] IS NOT NULL AND Year([TransactionDate]) IN (2015,2016)) AS [% of Sales]

FROM [WideWorldImporters].[Sales].[CustomerTransactions]
JOIN 
(
SELECT 
[WideWorldImporters].[Sales].[Customers].[CustomerID]
,[CustomerCategoryName]

FROM [WideWorldImporters].[Sales].[Customers]
LEFT JOIN [WideWorldImporters].[Sales].[CustomerCategories] on [WideWorldImporters].[Sales].[Customers].[CustomerCategoryID]=[WideWorldImporters].[Sales].[CustomerCategories].[CustomerCategoryID]
) AS B
ON [WideWorldImporters].[Sales].[CustomerTransactions].[CustomerID]=B.[CustomerID]
WHERE [InvoiceID] IS NOT NULL AND Year([TransactionDate]) IN (2015,2016)
GROUP BY [CustomerCategoryName] 
ORDER BY [% of Sales] DESC;

--#4 Querying Total Monthly Sales Data including a rolling past 12 month total, past 12 month avg, and % change month over month for each of the metrics

--First we create a CTE to group the daily transactions into monthly totals
WITH [Monthly Data] AS 
(
SELECT
Month([TransactionDate]) AS Month
,Year([TransactionDate]) AS Year
,SUM([TransactionAmount]) AS [Total Monthly Invoiced Amount]

FROM [WideWorldImporters].[Sales].[CustomerTransactions]
WHERE [InvoiceID] IS NOT NULL
GROUP BY Year([TransactionDate]), Month([TransactionDate])
)
,
--Secondly, we then add a row number to the dataset 
[Ranked Monthly Data] AS 
(
SELECT 
ROW_NUMBER() OVER(ORDER BY Year, Month) AS [Rownumber]
,*
FROM [Monthly Data]
)
,
--Thirdly, using the rownumbers, we calculate a column that has the sum of the current row + 11 past months of total invoiced amounts (i.e a rolling 12 month total)
--We also create a column to calculate the average monthly total invoiced amounts of the past 12 months
[Monthly Data with Annual Avg] AS 
(
SELECT 
*
,(SELECT SUM([Total Monthly Invoiced Amount]) FROM [Ranked Monthly Data] AS B WHERE [B].[Rownumber] BETWEEN ([A].[Rownumber]-11) AND [A].[Rownumber]) AS [12 month total]
,(SELECT SUM([Total Monthly Invoiced Amount]) FROM [Ranked Monthly Data] AS C WHERE [C].[Rownumber] BETWEEN ([A].[Rownumber]-11) AND [A].[Rownumber])
/(SELECT COUNT([Rownumber]) FROM [Ranked Monthly Data] AS D WHERE [D].[Rownumber] BETWEEN ([A].[Rownumber]-11) AND [A].[Rownumber]) AS [12 month avg]

FROM [Ranked Monthly Data] AS A
)
,
--Next, we create 2 new columns displaying the previous month's 12 month total, and avg monthly amount over the last 12 month  
[Monthly Data with Annual Avg Lag] AS 
(
SELECT *
,COALESCE(lag([Total Monthly Invoiced Amount], 1) over(ORDER BY Year, Month),0) AS [Previous Month Total Invoiced Amount]
,COALESCE(lag([12 month avg], 1) over(ORDER BY Year, Month),0) AS [Previous 12 month avg]

FROM [Monthly Data with Annual Avg]
)
--We also decide to add a column with the Month Name here, and also utilize the two new columns we created above to output 2 new columns that calculate the month over month % change
--We then also finetune our SELECT statement to output only the most relevant data columns
SELECT 
DATENAME(mm, DateAdd( mm ,[Month], 0 ) - 1 ) AS [Month Name]
,[Year]
,[Total Monthly Invoiced Amount]
,[12 month total]
,[12 month avg]
,ISNULL((([Total Monthly Invoiced Amount]-[Previous Month Total Invoiced Amount])/NULLIF([Previous Month Total Invoiced Amount],0))*100,0) AS [Monthly Growth]
,ISNULL((([12 month avg]-[Previous 12 month avg])/NULLIF([Previous 12 month avg],0))*100,0) AS [Rolling 12 month avg growth]

FROM [Monthly Data with Annual Avg Lag];

--#5 Querying Top Item Sales by Month alongside item rank based on profit per month, and profit and quantity % change month over month
--After transforming our data with a few CTEs, we create a view in our database that we can use further. 
--CREATE VIEW [Monthly Item Sales] AS

--This first CTE sums the profit and total quantity sold of Stock Item Ids into groups of month and year, and also joins them to include the Stock Item Name
WITH [Monthly Item Sales Data] AS 
(
SELECT 
Month([WideWorldImporters].[Sales].[Invoices].[InvoiceDate]) AS [Month]
,Year([WideWorldImporters].[Sales].[Invoices].[InvoiceDate]) AS [Year]
,[WideWorldImporters].[Sales].[InvoiceLines].[StockItemID]
,SUM([WideWorldImporters].[Sales].[InvoiceLines].[LineProfit]) AS [Profit]
,SUM([WideWorldImporters].[Sales].[InvoiceLines].[Quantity]) AS [Total Quantity Sold]
,(SUM([WideWorldImporters].[Sales].[InvoiceLines].[LineProfit])/SUM([WideWorldImporters].[Sales].[InvoiceLines].[Quantity])) AS [Profit per Item]

FROM [WideWorldImporters].[Sales].[InvoiceLines]
INNER JOIN [WideWorldImporters].[Sales].[Invoices] on [WideWorldImporters].[Sales].[InvoiceLines].[InvoiceID] = [WideWorldImporters].[Sales].[Invoices].[InvoiceID]
GROUP BY [WideWorldImporters].[Sales].[InvoiceLines].[StockItemID],Year([WideWorldImporters].[Sales].[Invoices].[InvoiceDate]), Month([WideWorldImporters].[Sales].[Invoices].[InvoiceDate])
)
,
--Secondly we then rank the items based on how well they sold in a particular month, and also add a column to show the previous month's profit & quantity sold of each item
[Ranked Monthly Item Sales Data] AS 
(
SELECT *
,RANK() OVER (PARTITION BY [Year],[Month] ORDER BY [Year],[Month],[Profit] DESC) AS [Rank]
,COALESCE(lag([Profit],1) over (PARTITION BY [StockItemID] ORDER BY [StockItemID],[Year],[Month]),0) AS [Previous Month Item Profit]
,COALESCE(lag([Total Quantity Sold],1) over (PARTITION BY [StockItemID] ORDER BY [StockItemID],[Year],[Month]),0) AS [Previous Month Item Sold]

FROM [Monthly Item Sales Data]
)
,
--Next, we calculate the % change for each item month over month in terms of item profit and the quantity sold
[Ranked Monthly Item Sales Data Growth] AS 
(
SELECT *
,ROUND(ISNULL(((CAST([Profit] as FLOAT)-[Previous Month Item Profit])/NULLIF([Previous Month Item Profit],0))*100,0),2) AS [Monthly Item Profit Growth]
,ROUND(ISNULL(((CAST([Total Quantity Sold] as FLOAT)-[Previous Month Item Sold])/NULLIF([Previous Month Item Sold],0)*100),0),2) AS [Monthly Item Sold Growth]

FROM [Ranked Monthly Item Sales Data]
)
,
--Next we fine tune the SELECT query, and add a Month Name column. 
[Monthly Sales] AS
(
SELECT
DATENAME(mm, DateAdd( mm ,[Month], 0 ) - 1 ) AS [Month Name]
,[Ranked Monthly Item Sales Data Growth].[Month]
,[Ranked Monthly Item Sales Data Growth].[Year]
,CAST([Ranked Monthly Item Sales Data Growth].[Rank] AS INT) AS [Rank]
,[Ranked Monthly Item Sales Data Growth].[StockItemID]
,[WideWorldImporters].[Warehouse].[StockItems].[StockItemName]
,[Ranked Monthly Item Sales Data Growth].[Profit]
,[Ranked Monthly Item Sales Data Growth].[Profit per Item]
,[Ranked Monthly Item Sales Data Growth].[Total Quantity Sold]
,[Ranked Monthly Item Sales Data Growth].[Monthly Item Profit Growth]
,[Ranked Monthly Item Sales Data Growth].[Monthly Item Sold Growth]

FROM [Ranked Monthly Item Sales Data Growth]
JOIN [WideWorldImporters].[Warehouse].[StockItems] ON [Ranked Monthly Item Sales Data Growth].[StockItemID]=[WideWorldImporters].[Warehouse].[StockItems].[StockItemID]
)
--Lastly, we also add a date column equal to the last day of the month for the corresponding monthly totals 
SELECT 
DATEADD(day,-1,DATEADD(month,1,CONVERT(datetime,[Month Name]+' 01,'+CAST([Year] as varchar(4)),107))) as [EOM Date]
,*
FROM [Monthly Sales];

--We use this query from the view we created to output an overall total for item profit & quantity sold
SELECT *
FROM (SELECT 
[StockItemName]
,SUM([Profit]) as [Total Profit]
,SUM([Total Quantity Sold]) as [Total Quantity Sold]
FROM [WideWorldImporters].[dbo].[Monthly Item Sales]
GROUP BY [StockItemName]) as [StockItemName]
ORDER BY [Total Profit] DESC;

--This query returns an entire history for items that have at least some point in sales history ranked within the top 10
SELECT *
FROM [WideWorldImporters].[dbo].[Monthly Item Sales]
WHERE [StockItemName] IN 
(
SELECT 
[StockItemName]
FROM [WideWorldImporters].[dbo].[Monthly Item Sales]
WHERE [RANK] BETWEEN 1 AND 10
GROUP BY [StockItemName]
)
ORDER BY [EOM Date],[Rank];



