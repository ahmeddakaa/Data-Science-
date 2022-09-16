---Inspecting Data
SELECT * FROM "Sales_data"

---Checking Unique Values
SELECT DISTINCT "STATUS" FROM "Sales_data"--- nice to plot
SELECT DISTINCT "YEAR_ID" from "Sales_data"
SELECT DISTINCT "PRODUCTLINE" FROM "Sales_data"---nice to plot
SELECT DISTINCT "COUNTRY" FROM "Sales_data"---nice to plot
SELECT DISTINCT "DEALSIZE" FROM "Sales_data"--- nice to plot
SELECT DISTINCT "TERRITORY" FROM "Sales_data"--- nice to plot

SELECT DISTINCT "MONTH_ID"
FROM "Sales_data"
WHERE ("YEAR_ID"::integer) = 2003



---Analysis
---Let's start by grouping Sales by Productline
SELECT "PRODUCTLINE" , SUM("SALES"::DECIMAL)
FROM "Sales_data"
GROUP BY "PRODUCTLINE"
ORDER BY 2 DESC

SELECT "YEAR_ID" , SUM("SALES"::DECIMAL)
FROM "Sales_data"
GROUP BY "YEAR_ID"
ORDER BY 2 DESC

SELECT "DEALSIZE", SUM("SALES"::decimal)
FROM "Sales_data"
GROUP BY "DEALSIZE"
ORDER BY 2 DESC

--- what was the best month for sales in a specific year? How much was earned that month?
SELECT "MONTH_ID",SUM("SALES"::decimal) AS Revenue, COUNT("ORDERNUMBER"::integer) AS FREQUENCY
FROM "Sales_data"
WHERE ("YEAR_ID"::integer) = 2003 --- change year to see the rest
GROUP BY "MONTH_ID"
ORDER BY 2 DESC

--- November seems to be the best month , what products do theysell in November , Classic I believe
SELECT "MONTH_ID","PRODUCTLINE",SUM("SALES"::decimal) AS Revenue, count("ORDERNUMBER"::integer) AS Frequency
FROM "Sales_data"
WHERE ("MONTH_ID"::integer)= 11
AND ("YEAR_ID"::integer) = 2003 --- change the year to see the rest
GROUP BY "MONTH_ID", "PRODUCTLINE"
ORDER BY 3 DESC

---Who is the best customer (this could be best answered with FRM)

DROP TABLE IF EXISTS Temp_RFM
; WITH RFM AS
           (SELECT "CUSTOMERNAME",
                   SUM("SALES"::decimal)                                          AS MonetaryValue,
                   AVG("SALES"::decimal)                                          AS AVGMonetaryValue,
                   COUNT("ORDERNUMBER")                                           AS Frequncy,
                   MAX("CONTACTFIRSTNAMEORDERDATE")                               AS last_Order_Date,
                   (SELECT MAX("CONTACTFIRSTNAMEORDERDATE") FROM "Sales_data")    AS Max_Order_Date,
                   extract(day from (SELECT MAX("CONTACTFIRSTNAMEORDERDATE"::timestamp) FROM "Sales_data") -
                                    MAX("CONTACTFIRSTNAMEORDERDATE" ::timestamp)) AS Recency
            FROM "Sales_data"
            GROUP BY "CUSTOMERNAME")


,RFM_calc AS (SELECT r.*,
                     NTILE(4) OVER (ORDER BY Recency DESC)     AS RFM_Recency,
                     NTILE(4) OVER (ORDER BY Frequncy)         AS RFM_Frequency,
                     NTILE(4) OVER (ORDER BY AVGMonetaryValue) AS RFM_Monetary


              FROM RFM AS r)

SELECT c.*,RFM_Recency + RFM_Frequency + RFM_Monetary AS RFM_Cell,
CONCAT(RFM_Recency :: varchar, RFM_Frequency :: varchar , RFM_Monetary :: varchar) AS RFM_STRING
INTO Temp_RFM
FROM RFM_calc AS c

SELECT "CUSTOMERNAME",RFM_Recency ,RFM_Frequency , RFM_Monetary
FROM temp_rfm

select "CUSTOMERNAME" , rfm_recency, rfm_frequency, rfm_monetary,RFM_STRING,
	case
		when RFM_STRING ::integer in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when RFM_STRING ::integer in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when RFM_STRING ::integer in (311, 411, 331) then 'new customers'
		when RFM_STRING ::integer in (222, 223, 233, 322) then 'potential churners'
		when RFM_STRING ::integer in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when RFM_STRING ::integer in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

INTO rfm_Analysis_1

from temp_rfm

---Move RFM Analysis into new table.
SELECT r."CUSTOMERNAME",r."rfm_segment",s."COUNTRY"
INTO rfm_table_ForVisualisation
FROM rfm_Analysis_1 AS r
LEFT JOIN "Sales_data" AS S
ON r."CUSTOMERNAME" = s."CUSTOMERNAME"
WHERE r.rfm_segment IS NOT NULL
GROUP BY r."CUSTOMERNAME", r."rfm_segment", s."COUNTRY"

---What are products are most often sold together ?
SELECT DISTINCT c."ORDERNUMBER",Purchased_together
INTO Most_sold_products
FROM (SELECT "ORDERNUMBER",string_agg("PRODUCTLINE",',') AS Purchased_together
FROM "Sales_data" AS s
WHERE "STATUS"='Shipped'
GROUP BY "ORDERNUMBER"
HAVING COUNT(*)=3 ) AS c
GROUP BY c.Purchased_together,c."ORDERNUMBER"
ORDER BY 2 DESC

SELECT *,
ROW_NUMBER() OVER (PARTITION BY purchased_together ORDER BY purchased_together)
FROM most_sold_products)

---What city has the highest number of sales in a specific country
select "CITY", sum ("SALES"::decimal) AS Revenue
from "Sales_data"
where "COUNTRY" = 'UK'
group by "CITY"
order by 2 desc

---What is the best product in United States?
select "COUNTRY", "YEAR_ID", "PRODUCTLINE", sum("SALES"::decimal) Revenue
from "Sales_data"
where "COUNTRY" = 'USA'
group by  "COUNTRY", "YEAR_ID", "PRODUCTLINE"
order by 4 desc
