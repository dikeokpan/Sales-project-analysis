---INSPECTING THE DATA
use [ProjectDB]

select *
from [dbo].[sales_data]


---CHECKING UNIQUE VALUES
select distinct STATUS
from [dbo].[sales_data]
select distinct YEAR_ID
from [dbo].[sales_data]
select distinct PRODUCTLINE
from [dbo].[sales_data]
select distinct COUNTRY
from [dbo].[sales_data]
select distinct DEALSIZE
from [dbo].[sales_data]
select distinct TERRITORY
from [dbo].[sales_data]


--- ANALYSIS
---------------------------------------------------------------------------------------------------------------------------------------------------
--1. Group Sales by Productline
select productline, sum(SALES) revenue
from [dbo].[sales_data]
group by productline
order by 2 desc
--- classic cars generated most revenue

--------------------------------------------------------------------------------------------------------------------------------------------------
--2. Year With The Most Sales
select YEAR_ID, sum(SALES) revenue
from [dbo].[sales_data]
group by YEAR_ID
order by 2 desc
---2004 has the highest sales

----------------------------------------------------------------------------------------------------------------------------------------------------
--3. 2005 Recorded The Lowest Sales from the Data Above. Did They Run a Full Year Operation?
select distinct MONTH_ID
from [dbo].[sales_data]
where YEAR_ID = 2005
--- operation in 2005 was just for 5 months

---------------------------------------------------------------------------------------------------------------------------------------------------
--4. Group Sales By Deal Size
select dealsize, sum(SALES) revenue
from [dbo].[sales_data]
group by dealsize
order by 2 desc
--- medium size sales generated the most revenue

---------------------------------------------------------------------------------------------------------------------------------------------------
--5. What Was The Best Month For Sales in a Specific Year? How Much Was Earned That Month?
select month_id, sum(SALES) revenue, count(ORDERNUMBER)frequency
from [dbo].[sales_data]
where year_id = 2003
group by MONTH_ID
order by 2 desc
-- november recorded the highest sales

select month_id, sum(SALES) revenue, count(ORDERNUMBER)frequency
from [dbo].[sales_data]
where year_id = 2004
group by MONTH_ID
order by 2 desc
-- november recorded the highest sales

select month_id, sum(SALES) revenue, count(ORDERNUMBER)frequency
from [dbo].[sales_data]
where year_id = 2005
group by MONTH_ID
order by 2 desc
-- month of may recorded the highest sales

---------------------------------------------------------------------------------------------------------------------------------------------------
--6. What Are The Highest Selling Products in the Best Months Above in Their Respective Years
select PRODUCTLINE, month_id, sum(SALES) revenue, count(ORDERNUMBER)frequency
from [dbo].[sales_data]
where year_id = 2003 and MONTH_ID = 11
group by PRODUCTLINE, MONTH_ID
order by 2 desc
-- classic cars were the highest selling products in 2003

select PRODUCTLINE, month_id, sum(SALES) revenue, count(ORDERNUMBER)frequency
from [dbo].[sales_data]
where year_id = 2004 and MONTH_ID = 11
group by PRODUCTLINE, MONTH_ID
order by 2 desc
-- classic cars were the highest selling products in 2004

select PRODUCTLINE, month_id, sum(SALES) revenue, count(ORDERNUMBER)frequency
from [dbo].[sales_data]
where year_id = 2005 and MONTH_ID = 5
group by PRODUCTLINE, MONTH_ID
order by 2 desc
-- classics cars were the highest selling products in 2005

---------------------------------------------------------------------------------------------------------------------------------------------------
--7. Who are the Best set of Customers? Using RFM
drop table if exists #rfm;
with rfm as
(
select customername
, SUM(SALES) monetary_value
, AVG(SALES) avg_monetary_value
, COUNT(ORDERNUMBER) frequency
, MAX(ORDERDATE) last_order_date
, (select max(ORDERDATE) from sales_data) max_order_date
, DATEDIFF(dd, MAX(ORDERDATE), (select max(ORDERDATE) from sales_data)) recency
from sales_data
group by CUSTOMERNAME),

rfm_calc as
(
select r.*,
	NTILE(4) over (order by recency desc) rfm_recency,
	NTILE(4) over (order by frequency) rfm_frequency,
	NTILE(4) over (order by monetary_value) rfm_monetary_value
from rfm r)
select c.*
, rfm_recency + rfm_frequency + rfm_monetary_value RFM_cell
, CAST(rfm_recency as varchar) + CAST(rfm_frequency as varchar) + CAST(rfm_monetary_value as varchar) string_RFM_cell
into #rfm
from rfm_calc c

select CUSTOMERNAME, rfm_recency, rfm_frequency, rfm_monetary_value,
	case
		when string_RFM_cell in (111, 112, 121, 122, 123, 132, 211, 212, 214, 341) then 'lost customers'
		when string_RFM_cell in (133, 134, 143, 343, 244, 334, 343, 344) then 'slipping away, cannot lose'
		when string_RFM_cell in (311, 411, 331) then 'new customers'
		when string_RFM_cell in (222, 223, 233, 322) then 'potential customers'
		when string_RFM_cell in (321, 323, 332, 332, 422, 432) then 'active customers'		
		when string_RFM_cell in (433, 434, 443, 444) then 'loyal customers'
	end RFM_segment

from #rfm
--- 'Loyal Customers' are the best set of customers

---------------------------------------------------------------------------------------------------------------------------------------------------
-- 8. What 2 Products were Sold Together?
select distinct ORDERNUMBER, STUFF(
	
	(select ',' + PRODUCTCODE 
	from [dbo].[sales_data] b
	where ORDERNUMBER in
		(select ordernumber
		from 
			(select ORDERNUMBER, count(ORDERNUMBER) RN
			from [dbo].[sales_data]
			where STATUS = 'shipped'
			group by ORDERNUMBER)a
			where RN = 2)
	and b.ORDERNUMBER = c.ORDERNUMBER

	for xml path('')), 1,1,'') productcodes

from [dbo].[sales_data] c
order by 2 desc

