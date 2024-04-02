

----Question 1
------------------------------------Solution A------------------------------------
SELECT 
 P.ProductID
,P.Name
,P.Color
,P.ListPrice
,P.Size
FROM Production.Product P
EXCEPT
SELECT
 P.ProductID
,P.Name
,P.Color
,P.ListPrice
,P.Size
FROM Sales.SalesOrderDetail S JOIN Production.Product P
ON P.ProductID=S.ProductID

------------------------------------Solution B------------------------------------
SELECT
 P.ProductID
,P.Name
,P.Color
,P.ListPrice
,P.Size
FROM Production.Product P  LEFT JOIN Sales.SalesOrderDetail OD
ON P.ProductID=OD.ProductID
WHERE OD.SalesOrderID IS NULL




----Question 2
------------------------------------Solution A------------------------------------
SELECT C.CustomerID, C.LastName, C.FirstName
FROM(
		SELECT C.CustomerID, 
		ISNULL(P.FirstName, 'Unknown') AS FirstName,
		ISNULL(P.LastName, 'Unknown') As LastName
		FROM Sales.Customer C LEFT JOIN Person.Person P
		ON P.BusinessEntityID=C.PersonID
		EXCEPT
		SELECT C.CustomerID,
		ISNULL(P.FirstName, 'Unknown') AS FirstName,
		ISNULL(P.LastName, 'Unknown') As LastName
		FROM Sales.SalesOrderHeader S JOIN Sales.Customer C
		ON S.CustomerID=C.CustomerID
			 JOIN Person.Person P
		ON P.BusinessEntityID=C.PersonID
	)C
ORDER BY C.CustomerID

------------------------------------Solution B------------------------------------
SELECT 
 C.CustomerID
,ISNULL(LastName,'Unknown') AS [LastName]
,ISNULL(FirstName,'Unknown') AS [FirstName]
FROM Sales.Customer C LEFT JOIN Person.Person P
ON P.BusinessEntityID=C.PersonID
                      LEFT JOIN Sales.SalesOrderHeader SOH
ON SOH.CustomerID=C.CustomerID
WHERE SOH.SalesOrderID IS NULL
ORDER BY C.CustomerID




----Question 3
------------------------------------Solution A------------------------------------
SELECT
C.CustomerID,
C.FirstName,
C.LastName,
C.CountOfOrders
FROM(
		SELECT
		CustomerID,
		C.FirstName,
		C.LastName,
		C.CountOfOrders,
		ROW_NUMBER()OVER(ORDER BY RNK) AS RN
		FROM(
				SELECT
				C.CustomerID,
				C.FirstName,
				C.LastName,
				CountOfOrders,
				RANK()OVER(ORDER BY CountOfOrders DESC) AS RNK
				FROM(
						SELECT
						COUNT(S.SalesOrderID) AS CountOfOrders,
						C.CustomerID,
						P.FirstName,
						P.LastName
						FROM Sales.SalesOrderHeader S JOIN Sales.Customer C
						ON S.CustomerID=C.CustomerID
								JOIN Person.Person P
						ON P.BusinessEntityID=C.PersonID
						GROUP BY C.CustomerID, P.FirstName, P.LastName
						)C
						   )C
						       )C
WHERE C.RN<=10

------------------------------------Solution B------------------------------------
WITH CTE
AS
(
SELECT DISTINCT 
 C.CustomerID
,P.FirstName
,P.LastName
,COUNT(SOH.SalesOrderID)OVER(PARTITION BY SOH.CustomerID ORDER BY C.CustomerID DESC) AS [CountOfOrders]
FROM Sales.SalesOrderHeader SOH JOIN Sales.Customer C
ON SOH.CustomerID=C.CustomerID
                                JOIN Person.Person P
ON P.BusinessEntityID=C.PersonID
),
CTE1
AS
(
SELECT 
 CTE.*
,ROW_NUMBER()OVER(ORDER BY CountOfOrders DESC) AS RN
FROM CTE
)
SELECT
 CustomerID
,FirstName
,LastName
,CountOfOrders
FROM CTE1
WHERE RN BETWEEN 1 AND 10




----Question 4
------------------------------------Solution A------------------------------------
SELECT 
 P.FirstName
,P.LastName
,E.JobTitle
,E.HireDate
,          (SELECT COUNT(*)
		    FROM HumanResources.Employee E1 
		    WHERE E1.JobTitle = E.JobTitle) AS [CountOfTitle]
FROM HumanResources.Employee E JOIN Person.Person P
ON E.BusinessEntityID=P.BusinessEntityID


------------------------------------Solution B------------------------------------
SELECT
 P.FirstName
,P.LastName
,E.JobTitle
,E.HireDate
,COUNT(JobTitle)OVER(PARTITION BY E.JobTitle ORDER BY E.JobTitle) AS [CountOfTitle]
FROM HumanResources.Employee E JOIN Person.Person P
ON E.BusinessEntityID=P.BusinessEntityID
 



----Question 5
------------------------------------Solution A------------------------------------
WITH TBL1
AS
(
SELECT
 SOH.SalesOrderID
,C.CustomerID
,P.FirstName
,P.LastName
,LAG(OrderDate,1)OVER(PARTITION BY C.PersonID ORDER BY SOH.OrderDate) AS [PrevOrder]
,RANK()OVER(PARTITION BY C.PersonID ORDER BY SOH.OrderDate DESC) AS RNK
,OrderDate AS [LastOrder]
FROM Sales.SalesOrderHeader SOH JOIN Sales.Customer C
ON C.CustomerID=SOH.CustomerID
	                            JOIN Person.Person P
ON P.BusinessEntityID=C.PersonID
)
SELECT 
 SalesOrderID
,CustomerID
,FirstName
,LastName
,lastOrder
,PrevOrder
FROM TBL1
WHERE RNK=1


------------------------------------Solution B------------------------------------
WITH TBL
AS
(
SELECT 
 SOH.SalesOrderID
,C.CustomerID
,C.PersonID
,P.LastName
,P.FirstName
,SOH.OrderDate AS [LastOrder],
LAG(OrderDate,1)OVER(PARTITION BY C.PersonID ORDER BY OrderDate) AS [PreviousOrder]
FROM sales.SalesOrderHeader SOH JOIN Sales.Customer C
ON SOH.CustomerID=C.CustomerID
JOIN Person.Person P
ON P.BusinessEntityID=C.PersonID
)
SELECT 
 SalesOrderID
,CustomerID
,LastName 
,FirstName 
,LastOrder
,PreviousOrder
FROM TBL T1
WHERE T1.LastOrder  IN(SELECT MAX(T2.LastOrder)
                       FROM TBL T2
                       WHERE T1.CustomerID=T2.CustomerID)
 



----Question 6
------------------------------------Solution A------------------------------------
WITH CTE
AS
(
SELECT
 SOH.SalesOrderID
,YEAR(OrderDate) AS [Year]
,P.FirstName
,P.LastName
,SUM(OD.LineTotal) AS [Total]
FROM Sales.SalesOrderHeader SOH JOIN Sales.SalesOrderDetail OD
ON SOH.SalesOrderID=OD.SalesOrderID
                                JOIN Sales.Customer C
ON C.CustomerID=SOH.CustomerID
                                JOIN Person.Person P
ON P.BusinessEntityID=C.PersonID
GROUP BY SOH.SalesOrderID
        ,YEAR(OrderDate)
		,P.FirstName
        ,P.LastName
),
CTE1
AS
(
SELECT CTE.*,
ROW_NUMBER()OVER(PARTITION BY Year ORDER BY Total DESC) AS [RN]
FROM CTE
)
SELECT
 Year
,SalesOrderID
,LastName
,FirstName
,Total
FROM CTE1
WHERE RN=1




----Question 7
------------------------------------Solution A------------------------------------
SELECT
 [Month]
,ISNULL([2011],'0') AS [2011]
,ISNULL([2012],'0') AS [2012]
,ISNULL([2013],'0') AS [2013]
,ISNULL([2014],'0') AS [2014]
FROM
(
		 SELECT
		 DATEPART(YEAR,OrderDate) AS [Year]
		,DATEPART(MONTH,OrderDate) AS [Month]
		,COUNT(SalesOrderID) AS [Orders]
		FROM Sales.SalesOrderHeader
		GROUP BY DATEPART(YEAR,OrderDate) ,DATEPART(MONTH,OrderDate)
)DataForPivot
PIVOT(SUM(Orders) FOR [Year] IN([2011],[2012],[2013],[2014])) AS PivotSuccses

------------------------------------Solution B------------------------------------
SELECT 
 [Month]
,ISNULL([2011],'0') AS [2011]
,ISNULL([2012],'0') AS [2012]
,ISNULL([2013],'0') AS [2013]
,ISNULL([2014],'0') AS [2014]
FROM 
(
    SELECT YEAR(OrderDate) AS [Year]
          ,MONTH(OrderDate) AS [Month], 
           COUNT(*) AS [Orders]
    FROM Sales.SalesOrderHeader
    GROUP BY YEAR(OrderDate), MONTH(OrderDate)
) AS DataForPivot
PIVOT
(
    SUM([Orders])
    FOR [Year] IN ([2011], [2012], [2013], [2014])
) AS PivotTable




----Question 8
------------------------------------Solution A------------------------------------
WITH C
AS
(
SELECT 
     DATEPART(YEAR, OrderDate) AS [Year]
    ,DATEPART(MONTH, OrderDate) AS [Month]
    ,SUM(SubTotal) AS [SumTotal]
	,SUM(SUM(SubTotal)) OVER (PARTITION BY DATEPART(YEAR, OrderDate) ORDER BY DATEPART(Month, OrderDate)) AS [CumTotal]
FROM 
    Sales.SalesOrderHeader
GROUP BY DATEPART(YEAR, OrderDate),DATEPART(MONTH, OrderDate)
)
SELECT
 C.Year
,ISNULL(CAST(C.Month AS VARCHAR),'GrandTotal') AS [Month]
,C.SumTotal
,MAX(C.CumTotal) AS [CumTotal]
FROM C
GROUP BY GROUPING SETS((C.Year,C.Month,C.SumTotal),C.Year)


------------------------------------Solution B------------------------------------

SELECT 
 S.OrderYear
,CASE WHEN S.OrderMonth IS NULL THEN 'Grand Total' 
      ELSE CAST(S.OrderMonth AS VARCHAR) 
	  END AS [OrderMonth]
,FORMAT(S.MonthlySales,'#,#.00') AS[MonthlySales]
,FORMAT(MAX(S.cum_total),'#,#.00') AS [CumulativeTotal]
FROM 
(     
		  SELECT
		  YEAR(OrderDate) AS OrderYear,
		  MONTH(OrderDate) AS OrderMonth,
		  SUM(SubTotal) AS MonthlySales,
		  SUM(SUM(SubTotal)) OVER (PARTITION BY YEAR(OrderDate) ORDER BY MONTH(OrderDate)) cum_total   
		  FROM Sales.SalesOrderHeader
		  GROUP BY YEAR(OrderDate), MONTH(OrderDate)
)S 
GROUP BY GROUPING SETS 
(    
(S.OrderYear,S.OrderMonth,S.MonthlySales)
,S.OrderYear
);

 ----Question 9
------------------------------------Solution A------------------------------------
WITH CTE
AS
(
SELECT
 D.Name AS [DepartmentName]
,E.BusinessEntityID AS [EmployeesID]
,CONCAT_WS(' ',P.FirstName,P.LastName) AS [EmployeesFullName]
,E.HireDate
,DATEDIFF(Month,E.HireDate,GETDATE()) AS [Seniority]
,LEAD(E.HireDate,1)OVER(PARTITION BY D.DepartmentID ORDER BY E.HireDate DESC) AS [PrevHireDate]
,LEAD(P.FirstName+' '+P.LastName,1)OVER(PARTITION BY D.DepartmentID ORDER BY E.HireDate DESC) AS [PreviousEmployeesName]
FROM HumanResources.Employee E JOIN HumanResources.EmployeeDepartmentHistory DH
ON E.BusinessEntityID=DH.BusinessEntityID
            JOIN HumanResources.Department D
ON D.DepartmentID=DH.DepartmentID
            JOIN Person.Person P
ON P.BusinessEntityID=E.BusinessEntityID
WHERE DH.EndDate IS NULL
)
SELECT
 C.DepartmentName
,C.EmployeesFullName
,C.EmployeesID
,C.HireDate
,C.Seniority
,C.PrevHireDate
,C.PreviousEmployeesName
,DATEDIFF(DD,C.PrevHireDate,C.HireDate) AS [DiffDays]
FROM CTE C
ORDER BY C.DepartmentName



--Question 10
------------------------------------Solution A------------------------------------
SELECT
    E.HireDate
   ,D.DepartmentID
   ,STUFF(
        (
            SELECT ', '+CONCAT_WS(' ',CAST(E1.BusinessEntityID AS VARCHAR), P.FirstName, P.LastName)
            FROM HumanResources.Employee E1
            JOIN HumanResources.EmployeeDepartmentHistory D1 ON E1.BusinessEntityID = D1.BusinessEntityID
			JOIN Person.Person P ON P.BusinessEntityID=E1.BusinessEntityID
            WHERE E1.HireDate = E.HireDate AND D1.DepartmentID = D.DepartmentID
            FOR XML PATH('')
        ), 1, 1, ''
    ) AS Employees
FROM HumanResources.Employee E
JOIN HumanResources.EmployeeDepartmentHistory D ON E.BusinessEntityID = D.BusinessEntityID
WHERE D.EndDate IS NULL
GROUP BY D.DepartmentID, E.HireDate
ORDER BY  E.HireDate






