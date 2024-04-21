/*Writing query to identify main table from which to gather information. 
Business question: Profitability and revenue study of AdventureWorks' sales in 2011-2014. Are bikes worth it? */

select h.OrderDate,
	h.SubTotal,
	h.TotalDue,
	d.LineTotal,
	d.UnitPrice,
	d.UnitPriceDiscount,
	d.OrderQty,
	p.FinishedGoodsFlag,
	p.ProductID,
	p.StandardCost,
	p.ListPrice,
	p.ProductSubcategoryID,
	sc.ProductCategoryID,
	pc.Name as ProductCategoryName,
	so.DiscountPct,
	so.MaxQty,
	so.MinQty,
	so.Category
from Production.Product p
	left join Production.ProductSubCategory sc
		on p.ProductSubcategoryID=sc.ProductSubcategoryID
	left join Production.ProductCategory pc
		on sc.ProductCategoryID = pc.ProductCategoryID
	left join Sales.SalesOrderDetail d
		on p.ProductID = d.ProductID
	left join Sales.SalesOrderHeader h
		on d.SalesOrderID=h.SalesOrderID
	left join Sales.SpecialOfferProduct sop
		on d.ProductID = sop.ProductID 
	left join Sales.SpecialOffer so
		on sop.SpecialOfferID = so.SpecialOfferID
where OrderDate is not null and sc.ProductCategoryID is not null

--fixing the formating issue that messes up order
--results to be made into pie chart
select 
	format(sum((p.ListPrice - p.StandardCost)*d.OrderQty), '#,###') as Profit, --formating changed results' order and profit values. WHY?
	sc.ProductCategoryID,
	pc.Name as ProductCategoryName
from Production.Product p
	left join Production.ProductSubCategory sc
		on p.ProductSubcategoryID=sc.ProductSubcategoryID
	left join Production.ProductCategory pc
		on sc.ProductCategoryID = pc.ProductCategoryID
	left join Sales.SalesOrderDetail d 
		on p.ProductID = d.ProductID
	left join Sales.SalesOrderHeader h
		on d.SalesOrderID=h.SalesOrderID
	left join Sales.SpecialOfferProduct sop
		on d.ProductID = sop.ProductID 
	left join Sales.SpecialOffer so
		on sop.SpecialOfferID = so.SpecialOfferID 
group by sc.ProductCategoryID,  pc.Name
order by Profit desc -- Why is it not in order?


/* Ranking most profitable subcategory of products from AdventureWorks. */
select sum((p.ListPrice - p.StandardCost)*d.OrderQty) as UnfilteredProfit,
	format(sum((p.ListPrice - p.StandardCost)*d.OrderQty), '#,###') as FriendlyUnfilteredProfit,
	sc.ProductCategoryID,
	pc.Name as ProductCategoryName
from Production.Product p
	left join Production.ProductSubCategory sc
		on p.ProductSubcategoryID=sc.ProductSubcategoryID
	left join Production.ProductCategory pc
		on sc.ProductCategoryID = pc.ProductCategoryID
	left join Sales.SalesOrderDetail d 
		on p.ProductID = d.ProductID
	left join Sales.SalesOrderHeader h
		on d.SalesOrderID=h.SalesOrderID
	left join Sales.SpecialOfferProduct sop
		on d.ProductID = sop.ProductID 
	left join Sales.SpecialOffer so
		on sop.SpecialOfferID = so.SpecialOfferID 
where sc.ProductCategoryID is not null and OrderDate is not null
group by sc.ProductCategoryID,  pc.Name
order by FriendlyUnfilteredProfit desc 

/*Create panel */

select h.OrderDate,
	h.SubTotal,
	h.TotalDue,
	d.LineTotal,
	d.UnitPrice,
	d.UnitPriceDiscount,
	d.OrderQty,
	p.FinishedGoodsFlag,
	p.ProductID,
	p.StandardCost,
	p.ListPrice,
	p.ProductSubcategoryID,
	sc.ProductCategoryID,
	pc.Name as ProductCategoryName
into #panel_Project1
from Production.Product p
	left join Production.ProductSubCategory sc
		on p.ProductSubcategoryID=sc.ProductSubcategoryID
	left join Production.ProductCategory pc
		on sc.ProductCategoryID = pc.ProductCategoryID
	left join Sales.SalesOrderDetail d
		on p.ProductID = d.ProductID
	left join Sales.SalesOrderHeader h
		on d.SalesOrderID=h.SalesOrderID
where OrderDate is not null and sc.ProductCategoryID is not null;



--View panel to check tabel:
select *
from #panel_Project1;

--Checking available data - the time period analysed
select 
	min(OrderDate) as OrderDateBegin,
	max(OrderDate) as OrderDateEnd
from Sales.SalesOrderHeader

--Test the basic variables
--Observation 1: Clients with a large number of orders register orders with lower values
--Clients with orders between 7 and 20 register order values between $300 and $1.163 per order
select 
	CustomerID,
	Year(OrderDate) as OrderYear,
	sum(SubTotal) as TotalSalesPerCustomer,
	count(SalesOrderID) as NoOfOrders 
from Sales.SalesOrderHeader 
group by CustomerID, Year(OrderDate)
order by NoOfOrders desc

--Observation 2: clients with fewer orders register some of the high value orders
select 
	CustomerID,
	Year(OrderDate) as OrderYear,
	sum(SubTotal) as TotalSalesPerCustomer,
	count(SalesOrderID) as NoOfOrders 
from Sales.SalesOrderHeader 
group by CustomerID, Year(OrderDate)
order by TotalSalesPerCustomer desc

--How are the clients ordering? Predominantly via internet.
--Assumed that OnlineOrderFlag = 1 and OnlineOrderFlag = 0 - offline = clientul bought instore
select 
	OnlineOrderFlag,
	Year(OrderDate) as YearOfOrder,
	case 
		when OnlineOrderFlag = 0 then count(*)
		else count(*)
	end as NoOfOrdersOnline
from Sales.SalesOrderHeader
group by OnlineOrderFlag,Year(OrderDate)
order by YearOfOrder 

/*Data Check for OrderDate*/
--Is there null data?
select *
from #panel_Project1
where OrderDate is NULL;

--Check values for data error, exceptional or extreme values, and matching information type:
select OrderDate,
	Count(*) NoOfTimes
from #panel_Project1
group by OrderDate
order by NoOfTimes desc;

/*Integrity check for ListPrice*/
--Check for Null values:
select *
from #panel_Project1
where ListPrice is Null;

--Check values for data error, exceptional or extreme values, and matching information type:
select ListPrice,
	Count(*) NoOfTimes
from #panel_Project1
group by ListPrice
order by NoOfTimes desc;

--Check for products with a ListPrice=0
select *
from #panel_Project1
where ListPrice=0;

/*Integrity check for StandardCost*/
--Check for Null values:
select *
from #panel_Project1
where StandardCost is Null;

--Check values for data error, exceptional or extreme values, and matching information type:
select StandardCost,
Count(*) NoOfTimes
from #panel_Project1
group by StandardCost
order by NoOfTimes desc;

--Check for products with a StandardCost=0
select *
from #panel_Project1
where StandardCost=0;

/*Integrity check for ProductSubCategoryID*/
--Check for Null values:
select *
from #panel_Project1
where ProductCategoryID is Null or ProductCategoryID=0 or ProductSubcategoryID is Null or ProductSubcategoryID=0 ;

--Check values for data error, exceptional or extreme values, and matching information type:
select ProductCategoryName,
Count(ProductCategoryID) NoOfIDsPerCategory
from #panel_Project1
group by ProductCategoryName
order by NoOfIDsPerCategory desc;



/*Integrity check for LineTotal*/
--Check for Null values:
select *
from #panel_Project1
where LineTotal is Null or LineTotal=0;

--Check values for data error, exceptional or extreme values, and matching information type:
select Sum(LineTotal) SumOfLineTotal,
	max(LineTotal) MaxLineTotal,
	min(LineTotal) MinLineTotal,
	Avg(LineTotal) AvgLineTotal
from #panel_Project1;

select LineTotal
from #panel_Project1;

/*Integrity check for LineTotal*/
--Check for Null values:
select *
from #panel_Project1
where SubTotal is Null or SubTotal=0;

--Check values for data error, exceptional or extreme values, and matching information type:
select Sum(SubTotal) SumOfSubTotal,
	max(SubTotal) MaxSubTotal,
	min(SubTotal) MinSubTotal,
	Avg(SubTotal) AvgSubTotal
from #panel_Project1;

select SubTotal
from #panel_Project1;

/*Integrity check for DiscountPct*/
--Check for Null values:
select *
from #panel_Project1
where DiscountPct is Null;

--Check values for data error, exceptional or extreme values, and matching information type:
select max(DiscountPct) MaxDiscountPct,
min(DiscountPct) MinDiscountPct,
Avg(DiscountPct) AvgDiscountPct
from #panel_Project1;

select DiscountPct
from #panel_Project1;

/*Integrity check for UnitPriceDiscount*/
--Check for Null values:
select *
from #panel_Project1
where UnitPriceDiscount is Null;

--Check values for data error, exceptional or extreme values, and matching information type:
select sum(((UnitPrice*(1-UnitPriceDiscount)-StandardCost)*OrderQty)) as RoughProfit,
max(UnitPriceDiscount) MaxUnitPriceDiscount,
min(UnitPriceDiscount) MinUnitPriceDiscount,
Avg(UnitPriceDiscount) AvgUnitPriceDiscount
from #panel_Project1;

select UnitPriceDiscount
from #panel_Project1
group by UnitPriceDiscount
order by UnitPriceDiscount desc;

/*CHECKING THE TABLES*/
--Checking table Production.Product - Column MakeFlag - out of a total of 504 Products, 265 are purchased (MakeFlag = 0) and  239 are manufactured in House and (MakeFlag = 1) 
select *
from Production.Product
where MakeFlag = 0 
--where MakeFlag = 1

--Checking what Products sells the Comoany the most, manugactured in House or purchased.
select 
	ProductID,
	[Name],
	MakeFlag,
	FinishedGoodsFlag,
	ProductSubcategoryID
from Production.Product
where ProductID in (select distinct ProductID
					from Sales.SalesOrderDetail)

select *
from Production.ProductCategory

select *
from Production.ProductSubcategory

--Checking table Production.Product - Column FinishedGoodsFlag = out of a 504 Products, 209 are products that are not salable (FinishedGoodsFlag = 0) and 
--295 are salable products (FinishedGoodsFlag = 1)
select *
from Production.Product
where FinishedGoodsFlag = 0
--where FinishedGoodsFlag = 1

--Checking table Production.Product - Column Class = out of a 504 Products, 
--97 are Low Class products (Class = L), 
--68 are Medium Class Product (Class = M), 
--82 are a High Class Products (Class = 'H')
--257 products do not have the class filled
--Class - H = High, M = Medium, L = Low
select *  
from Production.Product 
--where Class = 'L'
--where Class = 'M'
--where Class = 'H'
where Class is null

--Checking table Production.Product - Column Style - W = Womens, M = Mens, U = Universal = out of a 504 Products,
--28 are products with column Style = Womens,
--7 are products with column Style = Mens,
--176 are products with column Style = Universal,
--293 products do not have the class filled
select *
from Production.Product
--where Style = 'W'
--where Style = 'M'
--where Style = 'U'
where Style is null

select *
from Production.Product
where ListPrice = 0

--Checking table Production.Product - Column DaysToManufacture
select distinct DaysToManufacture,
	ProductSubcategoryID
from Production.Product
order by DaysToManufacture desc

--Checking table Production.Product and Sales.SalesOrderDetail and compare ListPrice VS UnitPrice
select d.SalesOrderID,
	d.OrderQty,
	p.ProductID,
	d.SpecialOfferID,
	d.UnitPrice,
	d.UnitPriceDiscount,
	p.StandardCost,
	p.ListPrice,
	p.ProductSubcategoryID
from Sales.SalesOrderDetail as d
	join Production.Product as p
	on d.ProductID = p.ProductID

--Checking table Sales.SalesOrderDetail - Column SpecialOffer - Discount Strategy
select distinct d.SpecialOfferID,
	so.Description as SpecialOfferDescription,
	so.DiscountPct as DiscountPercent,
	count(d.SpecialOfferID) as NoOfTimesSpecialOffer,
	sum(d.OrderQty) as QtyOrderbySpecialOrder,
	min(h.OrderDate) as BeginOffer,
	max(h.OrderDate) as EndOffer
from Sales.SalesOrderDetail as d
	join Sales.SpecialOffer as so
	on d.SpecialOfferID = so.SpecialOfferID
	join Sales.SalesOrderHeader as h
	on d.SalesOrderID = h.SalesOrderID
group by d.SpecialOfferID, so.Description, so.DiscountPct
order by so.DiscountPct desc

/*Total number of orders, divided by year */
--2013 was the most prolific year in number of products
--2011 was the least prolific year
select count(ProductID) as NoOfProductsOrdered,
	sum(OrderQty) as NoOfProductsOrdered2,
	Year(OrderDate) as Year
from #panel_Project1
group by Year(OrderDate)
order by NoOfProductsOrdered desc;

--Refining the query to incorporate the category names
select count(ProductID) as NoOfProductsOrdered,
	Year(OrderDate) as Year,
	ProductCategoryName
from #panel_Project1
group by ProductCategoryName, year(OrderDate)
order by NoOfProductsOrdered desc, Year desc;

--There appears to be a seasonality in the orders of bikes: the most popular season for bike orders are in the spring and winter.
select count(ProductID) as NoOfProductsOrdered,
	Month(OrderDate) as Month,
	ProductCategoryName
from #panel_Project1
where ProductCategoryName = 'Bikes'
group by ProductCategoryName, year(OrderDate), month(OrderDate)
order by NoOfProductsOrdered desc, month(OrderDate);


--MORE SEASONALITY CHECK
/*Analysis - the evolution of the number of orders between 2011 and 2014*/
select Year(OrderDate) as YearOrderDate,
	count(*) as NoOfOrders
from Sales.SalesOrderHeader
group by Year(OrderDate)
order by YearOrderDate

/*---Check how orders are distributed in terms of the value of products ordered compared to the average order values
--Conclusion:
--1. Total Average value of orders = 3.491,06 --Avg(SubTotal) - for all years studied (2011-2014)
--	Out of a total 31.465 orders, 27.458 have a Value (SubTotal) smaller than the Average value of orders
-- and 4.007 Orders have a Value (SubTotal) greater than or equal to the Average value of orders.*/
select 
	SalesOrderID, 
	SubTotal,
	(select Avg(SubTotal)
	 from Sales.SalesOrderHeader) as AvgSubTotal
from Sales.SalesOrderHeader
where SubTotal < (select Avg(SubTotal)
				from Sales.SalesOrderHeader)
Order by SubTotal

--For all the years 2011-2014
--evaluate how many Orders have a value (SubTotal) lower than the Average and how many greater than or equal to the Average value of orders 
select	
		case 
		   when DistFromAvg < 0 then 'Lower Then Avg'
		   else 'Above Then Avg'
		end as TextDiffFromAvg,
		count (*) CountNo
from (
	select 
		SalesOrderID,
		SubTotal- (select avg (SubTotal)
					from Sales.SalesOrderHeader ) DistFromAvg
	from sales.SalesOrderHeader
     ) ResultDistFromAvg
group by case 
	   		when DistFromAvg < 0 then 'Lower Then Avg'
			else 'Above Then Avg'
		end

--Same analysis for 2011
select	
		case 
		   when DistFromAvg < 0 then 'Lower Then Avg'
		   else 'Above Then Avg'
		end as TextDiffFromAvg,
		count (*) CountNo
from (
	select 
		SalesOrderID,
		SubTotal- (select avg (SubTotal)
					from Sales.SalesOrderHeader ) DistFromAvg
	from sales.SalesOrderHeader
	where Year(OrderDate) = 2011
     ) ResultDistFromAvg
group by case 
	   		when DistFromAvg < 0 then 'Lower Then Avg'
			else 'Above Then Avg'
		end

----Same analysis for 2012
select	
		case 
		   when DistFromAvg < 0 then 'Lower Then Avg'
		   else 'Above Then Avg'
		end as TextDiffFromAvg,
		count (*) CountNo
from (
	select 
		SalesOrderID,
		SubTotal- (select avg (SubTotal)
					from Sales.SalesOrderHeader ) DistFromAvg
	from sales.SalesOrderHeader
	where Year(OrderDate) = 2012
     ) ResultDistFromAvg
group by case 
	   		when DistFromAvg < 0 then 'Lower Then Avg'
			else 'Above Then Avg'
		end

----Same analysis for 2013
select	
		case 
		   when DistFromAvg < 0 then 'Lower Then Avg'
		   else 'Above Then Avg'
		end as TextDiffFromAvg,
		count (*) CountNo
from (
	select 
		SalesOrderID,
		SubTotal- (select avg (SubTotal)
					from Sales.SalesOrderHeader ) DistFromAvg
	from sales.SalesOrderHeader
	where Year(OrderDate) = 2013
     ) ResultDistFromAvg
group by case 
	   		when DistFromAvg < 0 then 'Lower Then Avg'
			else 'Above Then Avg'
		end

--Same analysis for 2014
select	
		case 
		   when DistFromAvg < 0 then 'Lower Then Avg'
		   else 'Above Then Avg'
		end as TextDiffFromAvg,
		count (*) CountNo
from (
	select 
		SalesOrderID,
		SubTotal- (select avg (SubTotal)
					from Sales.SalesOrderHeader ) DistFromAvg
	from sales.SalesOrderHeader
	where Year(OrderDate) = 2014
     ) ResultDistFromAvg
group by case 
	   		when DistFromAvg < 0 then 'Lower Then Avg'
			else 'Above Then Avg'
		end

-- Evolution of average order value 2011- 2014 --
select year(OrderDate) as [Year],
	avg(SubTotal) as AvgOrderValue,
	count(SalesOrderID) as NoOfOrders
from Sales.SalesOrderHeader
group by year(OrderDate)
order by year(OrderDate)

--checking the orders from 2011
select *
from Sales.SalesOrderDetail as d
	left join Sales.SalesOrderHeader as h
	on d.SalesOrderID = h.SalesOrderID
where year(OrderDate) = 2011
order by SubTotal desc

--Checking how many products order customer
Select OrderQty,
	COUNT(*) NoOfTimes
	from Sales.SalesOrderDetail
	group by OrderQty
	order by OrderQty

select *
from Sales.SalesOrderHeader
order by SubTotal desc

/*Checking how many product from each category was ordered*/
--Analysis for 2011-2014
select 
	pc.ProductCategoryID,
	pc.[Name],
	sum(d.OrderQty) as TotalOrderQty
from Sales.SalesOrderDetail as d
	left join Production.Product as p
		on d.ProductID = p.ProductID
	left join Production.ProductSubcategory as ps
		on p.ProductSubcategoryID = ps.ProductSubcategoryID
	left join Production.ProductCategory as pc
		on ps.ProductCategoryID = pc.ProductCategoryID
group by pc.ProductCategoryID, pc.[Name]
order by sum(d.OrderQty) desc

--Evolution of No of Product ordered per Category per each year
select 
	Year(OrderDate) as OrderYear,
	pc.ProductCategoryID,
	pc.[Name] as ProductCategoryName,
	sum(d.OrderQty) as TotalOrderQty
from Sales.SalesOrderDetail as d
	left join Sales.SalesOrderHeader as h
		on d.SalesOrderID = h.SalesOrderID
	left join Production.Product as p
		on d.ProductID = p.ProductID
	left join Production.ProductSubcategory as ps
		on p.ProductSubcategoryID = ps.ProductSubcategoryID
	left join Production.ProductCategory as pc
		on ps.ProductCategoryID = pc.ProductCategoryID
group by pc.ProductCategoryID, pc.[Name], Year(OrderDate)
order by Year(OrderDate), pc.ProductCategoryID, sum(d.OrderQty) desc

select *
from Production.ProductSubcategory

select *
from Production.ProductCategory

--Checking what type ok bike order customer the most 
--First check - for all the period 2011 - 2014
select 
	ps.ProductSubcategoryID as ProductSubcategoryID,
	ps.[Name] as ProductSubcategoryName,
	sum(d.OrderQty) as TotalOrderQtyPerSubcategory
from Sales.SalesOrderDetail as d
	left join Sales.SalesOrderHeader as h
		on d.SalesOrderID = h.SalesOrderID
	left join Production.Product as p
		on d.ProductID = p.ProductID
	left join Production.ProductSubcategory as ps
		on p.ProductSubcategoryID = ps.ProductSubcategoryID
	left join Production.ProductCategory as pc
		on ps.ProductCategoryID = pc.ProductCategoryID
where pc.ProductCategoryID = 1 --ProductCategoryID = 1 = Bikes
group by ps.ProductSubcategoryID, ps.[Name]
order by sum(d.OrderQty) desc

--Then check - for yeach year 2011 - 2014
select 
	ps.ProductSubcategoryID as ProductSubcategoryID,
	ps.[Name] as ProductSubcategoryName,
	sum(d.OrderQty) as TotalOrderQtyPerSubcategory,
	year(OrderDate) as Year
from Sales.SalesOrderDetail as d
	left join Sales.SalesOrderHeader as h
		on d.SalesOrderID = h.SalesOrderID
	left join Production.Product as p
		on d.ProductID = p.ProductID
	left join Production.ProductSubcategory as ps
		on p.ProductSubcategoryID = ps.ProductSubcategoryID
	left join Production.ProductCategory as pc
		on ps.ProductCategoryID = pc.ProductCategoryID
where pc.ProductCategoryID = 1 --ProductCategoryID = 1 = Bikes
group by ps.ProductSubcategoryID, ps.[Name], year(OrderDate)
order by year(OrderDate), sum(d.OrderQty) desc

/******PANEL CHECK*******/
--Revenue from PANEL - OK
select 
	sum(LineTotal) as TotalRevenueFormPanel,
	format(sum(LineTotal),'#,###') as TotalRevenueFriendlyFromPanel
from #panel_Project1

--Revenue from SalesOrderDetail
select 
	sum(d.LineTotal) as TotalRevenue,
	format(sum(d.LineTotal),'#,###') as TotalRevenueFriendly
from Sales.SalesOrderDetail as d
	left join Sales.SalesOrderHeader as h
	on d.SalesOrderID = h.SalesOrderID

--Revenue from SalesOrderHeader
select 
	sum(SubTotal) as TotalRevenue,
	format(sum(SubTotal),'#,###') as TotalRevenueFriendly
from Sales.SalesOrderHeader

--Evolution of Revenue - By Year
select 
	year(OrderDate) as YearOfOrder,
	sum(SubTotal) as TotalRevenue,
	format(sum(SubTotal),'#,###') as TotalRevenueFriendly
from Sales.SalesOrderHeader
group by year(OrderDate)
order by YearOfOrder

--Evolution of Revenue by No of Product ordered per each year
select 
	Year(OrderDate) as OrderYear,
	pc.ProductCategoryID,
	pc.[Name] as ProductCategoryName,
	sum(d.LineTotal) as RevenuePerProductCategory,
	format(sum(d.LineTotal),'#,###') as RevenuePerProductCategoryFriendly
from Sales.SalesOrderDetail as d
	left join Sales.SalesOrderHeader as h
		on d.SalesOrderID = h.SalesOrderID
	left join Production.Product as p
		on d.ProductID = p.ProductID
	left join Production.ProductSubcategory as ps
		on p.ProductSubcategoryID = ps.ProductSubcategoryID
	left join Production.ProductCategory as pc
		on ps.ProductCategoryID = pc.ProductCategoryID
group by pc.ProductCategoryID, pc.[Name], Year(OrderDate)
order by Year(OrderDate), pc.ProductCategoryID, sum(d.OrderQty) desc

-----Checking when orders are made (day of the week) and related Revenue 
select 
	datename (WeekDay,OrderDate) as SaleDay,
	count (*) as NoOfSales
from Sales.SalesOrderHeader
group by (datename (WeekDay,OrderDate))
Order by NoOfSales desc

select 
	sum(SubTotal) as SaleWeek,
	format(sum(SubTotal),'#,###') as SaleWeekFriendly,
	datename (WeekDay,OrderDate) as SaleDay
from Sales.SalesOrderHeader
group by datename (WeekDay,OrderDate)
Order by SaleWeek desc


/*Answering the business question: Profitability and revenue study of AdventureWorks' sales in 2011-2014. Are bikes worth it? */
--Filters needed for Profitability:
--Using the formula sum((UnitPrice*(1-UnitPriceDiscount)-StandardCost)OrderQty)= Profit, to rank profitability. 
select sum((UnitPrice*(1-UnitPriceDiscount)-StandardCost)*OrderQty) as Profit,
	ProductCategoryName,
	year(OrderDate) as Year
from #panel_Project1
where OrderDate is not null
group by ProductCategoryName, year(OrderDate)
order by year(OrderDate),Profit desc;

--Dividing the data according to ProductCategories
select sum((UnitPrice*(1-UnitPriceDiscount)-StandardCost)*OrderQty) as Profit,
	format(sum((UnitPrice-(1-UnitPriceDiscount)-StandardCost)*OrderQty), '#,###') as FriendlyProfit,
	ProductCategoryName
from #panel_Project1
group by ProductCategoryName
order by Profit desc;

--Dividing the data by Year(OrderDate) and month
select sum((UnitPrice*(1-UnitPriceDiscount)-StandardCost)*OrderQty) as Profit,
	format(sum((UnitPrice-(1-UnitPriceDiscount)-StandardCost)*OrderQty), '#,###') as FriendlyProfit,
	year(OrderDate) as YearOfOrderDate,
	ProductCategoryName
from #panel_Project1
group by ProductCategoryName, Year(OrderDate)
order by Profit desc,YearOfOrderDate;

--Dividing the data by Year(2011) and month
select sum((UnitPrice*(1-UnitPriceDiscount)-StandardCost)*OrderQty) as Profit,
	format(sum((UnitPrice-(1-UnitPriceDiscount)-StandardCost)*OrderQty), '#,###') as FriendlyProfit,
	month(OrderDate) as MonthOfOrderDate,
	ProductCategoryName
from #panel_Project1
where year(OrderDate)=2011
group by ProductCategoryName, month(OrderDate)
order by Profit desc,MonthOfOrderDate;

--Dividing the data by Year(2012) and month
select sum((UnitPrice*(1-UnitPriceDiscount)-StandardCost)*OrderQty) as Profit,
	format(sum((UnitPrice-(1-UnitPriceDiscount)-StandardCost)*OrderQty), '#,###') as FriendlyProfit,
	month(OrderDate) as MonthOfOrderDate,
	ProductCategoryName
from #panel_Project1
where year(OrderDate)=2012
group by ProductCategoryName, month(OrderDate)
order by Profit desc,MonthOfOrderDate;

--Dividing the data by Year(2013) and month
select sum((UnitPrice*(1-UnitPriceDiscount)-StandardCost)*OrderQty) as Profit,
	format(sum((UnitPrice-(1-UnitPriceDiscount)-StandardCost)*OrderQty), '#,###') as FriendlyProfit,
	month(OrderDate) as MonthOfOrderDate,
	ProductCategoryName
from #panel_Project1
where year(OrderDate)=2013
group by ProductCategoryName, month(OrderDate)
order by Profit desc,MonthOfOrderDate;

--Dividing the data by Year(2014) and month
select sum((UnitPrice*(1-UnitPriceDiscount)-StandardCost)*OrderQty) as Profit,
	format(sum((UnitPrice-(1-UnitPriceDiscount)-StandardCost)*OrderQty), '#,###') as FriendlyProfit,
	month(OrderDate) as MonthOfOrderDate,
	ProductCategoryName
from #panel_Project1
where year(OrderDate)=2014
group by ProductCategoryName, month(OrderDate)
order by Profit desc, MonthOfOrderDate;

--Profit calculation realisation: these give 3 different answers, as the 1st query does not account for the discounts accurately. By using the left join in the second query, we include more of the discounts left out. We will be using the table with the SpecialOffer tables, but with the profit formula of sum(UnitPrice-(1-UnitPriceDiscount)-StandardCost)OrderQty.

SELECT year(OrderDate), 
	SUM((UnitPrice * OrderQty) - (UnitPriceDiscount * OrderQty) - (Product.StandardCost * SalesOrderDetail.OrderQty)) AS Profit
FROM Sales.SalesOrderHeader 
	JOIN Sales.SalesOrderDetail 
		ON SalesOrderHeader.SalesOrderID = SalesOrderDetail.SalesOrderID 
	JOIN Production.Product 
		ON SalesOrderDetail.ProductID = Product.ProductID 
GROUP BY year(OrderDate);


SELECT year(OrderDate), 
	SUM( (UnitPrice * OrderQty) - (UnitPriceDiscount* OrderQty) - (Product.StandardCost * SalesOrderDetail.OrderQty) ) AS Profit
FROM Sales.SalesOrderHeader 
	JOIN Sales.SalesOrderDetail 
		ON SalesOrderHeader.SalesOrderID = SalesOrderDetail.SalesOrderID 
	JOIN Production.Product 
		ON SalesOrderDetail.ProductID = Product.ProductID 
	LEFT JOIN Sales.SpecialOfferProduct 
		ON SalesOrderDetail.ProductID = SpecialOfferProduct.ProductID 
	LEFT JOIN Sales.SpecialOffer 
		ON SpecialOfferProduct.SpecialOfferID = SpecialOffer.SpecialOfferID 
GROUP BY year(OrderDate);



SELECT year(OrderDate) as OrderYear, 
	SUM( (UnitPrice - (1-UnitPriceDiscount) - Product.StandardCost) * OrderQty) AS Profit
FROM Sales.SalesOrderHeader 
JOIN Sales.SalesOrderDetail 
ON SalesOrderHeader.SalesOrderID = SalesOrderDetail.SalesOrderID 
JOIN Production.Product 
ON SalesOrderDetail.ProductID = Product.ProductID 
LEFT JOIN Sales.SpecialOfferProduct 
ON SalesOrderDetail.ProductID = SpecialOfferProduct.ProductID 
LEFT JOIN Sales.SpecialOffer 
ON SpecialOfferProduct.SpecialOfferID = SpecialOffer.SpecialOfferID 
GROUP BY year(OrderDate);


/* Profit conclusions:*/

select sum((UnitPrice*(1-UnitPriceDiscount)-StandardCost)*OrderQty) as Profit,
	format(sum((UnitPrice*(1-UnitPriceDiscount)-StandardCost)*OrderQty), '#,###') as FriendlyProfit,
	year(OrderDate) as YearOfOrderDate,
	ProductCategoryName
from #panel_Project1
group by ProductCategoryName, year(OrderDate)
order by YearOfOrderDate, Profit desc;

-- No negative profits for any year.
-- All years have bikes in the top category names, in every year query. Bikes have the highest profitability, yearly.
-- For 2014, March and May have the most profitable Bike orders. However more data is needed for an accurate analysis.  
-- For 2013, Bikes have the highest profits for every month of the year.
-- For 2012, Bikes have the highest profits for every month of the year.
-- For 2011, Bikes have the highest profits from June to December.
-- In conclusion, Bikes get the highest profitable category out of all the categories.

/* For Revenue calculations: */
-- How to calculate revenue in AdventureWorks: TO DO//



--Tables SalesOrderHeaderSaleReason and SalesReason containing information about the reason for purchase
--they can be useful in a marketing study
--we have available info about the reason of buying for 27.647 orders  
select *
from Sales.SalesOrderHeaderSalesReason

--4.635 orders have more than one reason for buying selected (27.647 - 23.012 = 4.635),
--but the purpose of this analysis is to check what is the predominant reason for placing an order
select distinct SalesOrderID
from Sales.SalesOrderHeaderSalesReason

--we have 3 big Reason Types for buying from which the customer can choose (Mkt, Promotions, Other)
select distinct ReasonType
from Sales.SalesReason

--we have 10 Buying Reasons for buying from which the customer can choose
select *
from Sales.SalesReason
order by ReasonType

--31.465 total number of orders
select *
from Sales.SalesOrderHeader

--number of orders by reason for purchase; for 8.453 orders the customer did not fill in the reason for purchase
--to encourage customers to specify the reason for the sale, 
--the company can give a symbolic gift to complete the reason (reflective vest or safety accessory)
--based on the data obtained, graphs are generated
select 
	sr.SalesReasonID,
	sr.[Name] as ReasonOfBuying,
	count(*) as NoOfOrders
from Sales.SalesOrderHeader as h
left join Sales.SalesOrderHeaderSalesReason as hsr --hsr = HeaderSalesReason
on h.SalesOrderID = hsr.SalesOrderID
left join Sales.SalesReason as sr --sr = SalesReason
on hsr.SalesReasonID = sr.SalesReasonID
group by sr.SalesReasonID, sr.[Name]
order by NoOfOrders desc

--number of orders by Reason Types for buying from which the customer can choose (Mkt, Promotions, Other)
--based on the data obtained, graphs are generated
select 
	sr.ReasonType,
	count(*) as NoOfOrders
from Sales.SalesOrderHeader as h
left join Sales.SalesOrderHeaderSalesReason as hsr --hsr = HeaderSalesReason
on h.SalesOrderID = hsr.SalesOrderID
left join Sales.SalesReason as sr --sr = SalesReason
on hsr.SalesReasonID = sr.SalesReasonID
group by sr.ReasonType
order by NoOfOrders desc

--analysing the Reason Type - Other for buying - based on the data obtained, graphs are generated
select 
	sr.ReasonType,
	sr.[Name],
	count(*) as NoOfOrders
from Sales.SalesOrderHeader as h
left join Sales.SalesOrderHeaderSalesReason as hsr --hsr = HeaderSalesReason
on h.SalesOrderID = hsr.SalesOrderID
left join Sales.SalesReason as sr --sr = SalesReason
on hsr.SalesReasonID = sr.SalesReasonID
where sr.ReasonType = 'Other'
group by sr.ReasonType, sr.[Name]
order by NoOfOrders desc


/* Country of origin for order placement */
SELECT count(SalesOrderHeader.SalesOrderID) NumberOfOrders, 	
	CountryRegion.Name as Country,
	year(SalesOrderHeader.OrderDate) as OrderYear
FROM Sales.SalesOrderHeader
	JOIN Person.Address 
		ON SalesOrderHeader.ShipToAddressID = Address.AddressID
	JOIN Person.StateProvince 
		ON Address.StateProvinceID = StateProvince.StateProvinceID
	JOIN Person.CountryRegion 
		ON StateProvince.CountryRegionCode = CountryRegion.CountryRegionCode
Group by CountryRegion.Name, year(OrderDate)


/* Country of origin for order placement */
--I INTRODUCED AN ORDER BY
SELECT CountryRegion.Name as Country,
	count(SalesOrderHeader.SalesOrderID) NumberOfOrders, 	
	year(SalesOrderHeader.OrderDate) as OrderYear
FROM Sales.SalesOrderHeader
	JOIN Person.Address 
		ON SalesOrderHeader.ShipToAddressID = Address.AddressID
	JOIN Person.StateProvince 
		ON Address.StateProvinceID = StateProvince.StateProvinceID
	JOIN Person.CountryRegion 
		ON StateProvince.CountryRegionCode = CountryRegion.CountryRegionCode
Group by CountryRegion.Name, year(OrderDate)
Order by Year(OrderDate), NumberOfOrders

--Checking what type ok bike order customer the most 
--First check - for all the period 2011 - 2014
select month(OrderDate) as [Month],
	year(OrderDate) as [Year],
	sum(OrderQty) as QtyOrdered,
	sum(LineTotal) as TotalRevenue,
	sum(d.LineTotal - (p.StandardCost*d.OrderQty)) as TotalProfit,
from Sales.SalesOrderDetail as d
	left join Sales.SalesOrderHeader as h
		on d.SalesOrderID = h.SalesOrderID
	left join Production.Product as p
		on d.ProductID = p.ProductID
	left join Production.ProductSubcategory as ps
		on p.ProductSubcategoryID = ps.ProductSubcategoryID
where ps.ProductCategoryID = 1 --ProductCategoryID = 1 = Bikes
group by month(OrderDate), year(OrderDate)
order by year(OrderDate), QtyOrdered

--Checking the relationship between Profit and Revenue by YEAR
select 
	year(OrderDate) as YearOrderDate,
	sum(d.LineTotal - (p.StandardCost*d.OrderQty)) as TotalProfit,
	format(sum(d.LineTotal - (p.StandardCost*d.OrderQty)),'#,###') as FriendlyProfit,
	rank () over (Order by sum(d.LineTotal - (p.StandardCost*d.OrderQty)) desc) as YearRankProfit,
	sum(LineTotal) as Revenue,
	format(sum(LineTotal), '#,###') as FriendlyRevenue,
	rank() over (order by sum(LineTotal) desc) as YearRankRevenue
from Sales.SalesOrderHeader as h
 join Sales.SalesOrderDetail as d
	on h.SalesOrderID = d.SalesOrderID 
join Production.Product as p
	on d.ProductID = p.ProductID
group by Year(h.OrderDate)
order by Year(h.OrderDate)

--Checking the relationship between Profit and Revenue by MONTH
select 
	year(OrderDate) as [Year],
	month(OrderDate) as [Month],
	sum(d.LineTotal - (p.StandardCost*d.OrderQty)) as TotalProfit,
	format(sum(d.LineTotal - (p.StandardCost*d.OrderQty)),'#,###') as FriendlyProfit,
	rank () over (partition by year(OrderDate) Order by sum(d.LineTotal - (p.StandardCost*d.OrderQty)) desc) as MonthRankProfit,
	sum(LineTotal) as Revenue,
	format(sum(LineTotal), '#,###') as FriendlyRevenue,
	rank() over (partition by year(OrderDate) order by sum(LineTotal) desc) as MonthRankRevenue
from Sales.SalesOrderHeader as h
 join Sales.SalesOrderDetail as d
	on h.SalesOrderID = d.SalesOrderID 
join Production.Product as p
	on d.ProductID = p.ProductID
group by Year(h.OrderDate), month(OrderDate)
order by Year(h.OrderDate), month(OrderDate)

--Checking the relationship between Profit and Revenue by MONTH for 2011
select 
	year(OrderDate) as [Year],
	month(OrderDate) as [Month],
	sum(d.LineTotal - (p.StandardCost*d.OrderQty)) as TotalProfit,
	format(sum(d.LineTotal - (p.StandardCost*d.OrderQty)),'#,###') as FriendlyProfit,
	rank () over (partition by year(OrderDate) Order by sum(d.LineTotal - (p.StandardCost*d.OrderQty)) desc) as MonthRankProfit,
	sum(LineTotal) as Revenue,
	format(sum(LineTotal), '#,###') as FriendlyRevenue,
	rank() over (partition by year(OrderDate) order by sum(LineTotal) desc) as MonthRankRevenue
from Sales.SalesOrderHeader as h
 join Sales.SalesOrderDetail as d
	on h.SalesOrderID = d.SalesOrderID 
join Production.Product as p
	on d.ProductID = p.ProductID
where year(OrderDate) = 2011
group by Year(h.OrderDate), month(OrderDate)
order by month(OrderDate)

--Checking the relationship between Profit and Revenue by MONTH for 2012
select 
	year(OrderDate) as [Year],
	month(OrderDate) as [Month],
	sum(d.LineTotal - (p.StandardCost*d.OrderQty)) as TotalProfit,
	format(sum(d.LineTotal - (p.StandardCost*d.OrderQty)),'#,###') as FriendlyProfit,
	rank () over (partition by year(OrderDate) Order by sum(d.LineTotal - (p.StandardCost*d.OrderQty)) desc) as MonthRankProfit,
	sum(LineTotal) as Revenue,
	format(sum(LineTotal), '#,###') as FriendlyRevenue,
	rank() over (partition by year(OrderDate) order by sum(LineTotal) desc) as MonthRankRevenue
from Sales.SalesOrderHeader as h
 join Sales.SalesOrderDetail as d
	on h.SalesOrderID = d.SalesOrderID 
join Production.Product as p
	on d.ProductID = p.ProductID
where year(OrderDate) = 2012
group by Year(h.OrderDate), month(OrderDate)
order by month(OrderDate)

--Checking the relationship between Profit and Revenue by MONTH for 2013
select 
	year(OrderDate) as [Year],
	month(OrderDate) as [Month],
	sum(d.LineTotal - (p.StandardCost*d.OrderQty)) as TotalProfit,
	format(sum(d.LineTotal - (p.StandardCost*d.OrderQty)),'#,###') as FriendlyProfit,
	rank () over (partition by year(OrderDate) Order by sum(d.LineTotal - (p.StandardCost*d.OrderQty)) desc) as MonthRankProfit,
	sum(LineTotal) as Revenue,
	format(sum(LineTotal), '#,###') as FriendlyRevenue,
	rank() over (partition by year(OrderDate) order by sum(LineTotal) desc) as MonthRankRevenue
from Sales.SalesOrderHeader as h
 join Sales.SalesOrderDetail as d
	on h.SalesOrderID = d.SalesOrderID 
join Production.Product as p
	on d.ProductID = p.ProductID
where year(OrderDate) = 2013
group by Year(h.OrderDate), month(OrderDate)
order by month(OrderDate)

--Checking the relationship between Profit and Revenue by MONTH for 2014
select 
	year(OrderDate) as [Year],
	month(OrderDate) as [Month],
	sum(d.LineTotal - (p.StandardCost*d.OrderQty)) as TotalProfit,
	format(sum(d.LineTotal - (p.StandardCost*d.OrderQty)),'#,###') as FriendlyProfit,
	rank () over (partition by year(OrderDate) Order by sum(d.LineTotal - (p.StandardCost*d.OrderQty)) desc) as MonthRankProfit,
	sum(LineTotal) as Revenue,
	format(sum(LineTotal), '#,###') as FriendlyRevenue,
	rank() over (partition by year(OrderDate) order by sum(LineTotal) desc) as MonthRankRevenue
from Sales.SalesOrderHeader as h
 join Sales.SalesOrderDetail as d
	on h.SalesOrderID = d.SalesOrderID 
join Production.Product as p
	on d.ProductID = p.ProductID
where year(OrderDate) = 2014
group by Year(h.OrderDate), month(OrderDate)
order by month(OrderDate)

--Checking the different value for profit for different formulas 
--Checking the profit per category of product sold
select 
	sum(d.LineTotal - (p.StandardCost*d.OrderQty)) as RealProfit1,
	format(sum(d.LineTotal - (p.StandardCost*d.OrderQty)), '#,###') as RealProfit1Friendly,
	sum((d.UnitPrice*(1-d.UnitPriceDiscount)-p.StandardCost)*d.OrderQty) as RealProfit2,
	format(sum((d.UnitPrice*(1-d.UnitPriceDiscount)-p.StandardCost)*d.OrderQty),'#,###') as RealProfit2Friendly,
	sc.ProductCategoryID,
	pc.Name as ProductCategoryName
from Sales.SalesOrderDetail d 
	left join Sales.SalesOrderHeader h
		on d.SalesOrderID=h.SalesOrderID
	left join Production.Product p
		on d.ProductID = p.ProductID
	left join Production.ProductSubCategory sc
		on p.ProductSubcategoryID=sc.ProductSubcategoryID
	left join Production.ProductCategory pc
		on sc.ProductCategoryID = pc.ProductCategoryID
where OrderDate is not null and sc.ProductCategoryID is not null 
group by sc.ProductCategoryID,  pc.Name
order by sc.ProductCategoryID

--checking the Bike selling for the month June
select 
	year(OrderDate) as [Year],
	month(OrderDate) as [Month],
	ps.ProductCategoryID,
	sum(OrderQty) as OrderedQty
from Sales.SalesOrderHeader as h
 join Sales.SalesOrderDetail as d
	on h.SalesOrderID = d.SalesOrderID
join Production.Product as p
	on d.ProductID = p.ProductID
join Production.ProductSubcategory as ps
	on p.ProductSubcategoryID = ps.ProductSubcategoryID
where ps.ProductCategoryID = 1 
group by year(OrderDate), month(OrderDate), ps.ProductCategoryID
order by year(OrderDate), month(OrderDate)

select *
from Sales.SalesOrderHeader
where month(OrderDate)=6 and year(OrderDate)=2014

select *
from Production.ProductSubcategory

--Check which color have the Bikes
select Color,
	count(*) as NoOfProduct
from Production.Product
where ProductSubcategoryID in (1,2,3)
group by Color

--Orders in Oct. 2011 - discount 2% and 5%, all kinds of products ordered
select  
	pc.ProductCategoryID,
	sum(d.OrderQty) as TotalOrderQty
from Sales.SalesOrderDetail as d
	join Sales.SalesOrderHeader as h
	on d.SalesOrderID = h.SalesOrderID
	join Production.Product as p
	on d.ProductID = p.ProductID
	join Production.ProductSubcategory as ps
	on p.ProductSubcategoryID = ps.ProductSubcategoryID
	join Production.ProductCategory as pc
	on ps.ProductCategoryID = pc.ProductCategoryID
where h.OrderDate between '20111001' and '20111031'
group by pc.ProductCategoryID
order by ProductCategoryID

--Orders in Nov. 2011 - no discount, only bikes orders
select  
	pc.ProductCategoryID,
	sum(d.OrderQty) as TotalOrderQty
from Sales.SalesOrderDetail as d
	join Sales.SalesOrderHeader as h
	on d.SalesOrderID = h.SalesOrderID
	join Production.Product as p
	on d.ProductID = p.ProductID
	join Production.ProductSubcategory as ps
	on p.ProductSubcategoryID = ps.ProductSubcategoryID
	join Production.ProductCategory as pc
	on ps.ProductCategoryID = pc.ProductCategoryID
where h.OrderDate between '20111101' and '20111130'
group by pc.ProductCategoryID
order by ProductCategoryID

--Orders in Oct. 2011 - where do the orders go to? - There are 1.981 orders from US and Canada and 102 from Australia & Europe
select TerritoryID,
	count(*) as noOfOrdersByTerritory
from Sales.SalesOrderDetail as d
	join Sales.SalesOrderHeader as h
	on d.SalesOrderID = h.SalesOrderID
where h.OrderDate between '20111001' and '20111031'
group by TerritoryID
order by TerritoryID

--Orders in Nov. 2011 - where do the orders go to? - There are 100 orders from US and Canada and 130 from Australia & Europe
select TerritoryID,
	count(*) as noOfOrdersByTerritory
from Sales.SalesOrderDetail as d
	join Sales.SalesOrderHeader as h
	on d.SalesOrderID = h.SalesOrderID
where h.OrderDate between '20111101' and '20111130'
group by TerritoryID
order by TerritoryID

--Checking April 2012 selling - Profit is negative
select ProductSubcategoryID,
	UnitPriceDiscount,
	sum(OrderQty) as TotalQtyOrdered
from Sales.SalesOrderDetail as d
	join Sales.SalesOrderHeader as h
	on d.SalesOrderID = h.SalesOrderID
	join Production.Product as p
	on d.ProductID = p.ProductID
where h.OrderDate between '20120401' and '20120430'
group by ProductSubcategoryID, UnitPriceDiscount
order by ProductSubcategoryID


--Checking Feb. 2014 selling - low revenue - 799 bikes sold
select ProductSubcategoryID,
	UnitPriceDiscount,
	sum(OrderQty) as TotalQtyOrdered
from Sales.SalesOrderDetail as d
	join Sales.SalesOrderHeader as h
	on d.SalesOrderID = h.SalesOrderID
	join Production.Product as p
	on d.ProductID = p.ProductID
where h.OrderDate between '20140201' and '20140228'
group by ProductSubcategoryID, UnitPriceDiscount
order by ProductSubcategoryID

--Orders in Feb 2014 - where do the orders go to? - 2.076 orders for US+Canada; 2.205 orders for Europe+Australia
--the company sells Bikes = 799
select TerritoryID,
	count(*) as noOfOrdersByTerritory
from Sales.SalesOrderDetail as d
	join Sales.SalesOrderHeader as h
	on d.SalesOrderID = h.SalesOrderID
where h.OrderDate between '20140201' and '20140228'
group by TerritoryID
order by TerritoryID


--Checking March 2014 selling - The biggest revenue of all time
select ProductSubcategoryID,
	UnitPriceDiscount,
	sum(OrderQty) as TotalQtyOrdered
from Sales.SalesOrderDetail as d
	join Sales.SalesOrderHeader as h
	on d.SalesOrderID = h.SalesOrderID
	join Production.Product as p
	on d.ProductID = p.ProductID
where h.OrderDate between '20140301' and '20140331'
group by ProductSubcategoryID, UnitPriceDiscount
order by ProductSubcategoryID

--Orders in March 2014 - where do the orders go to? - 5.956 orders for US+Canada; 3.999 orders for Europe+Australia
--the company sells a lot of Bikes = 6.191
select TerritoryID,
	count(*) as noOfOrdersByTerritory
from Sales.SalesOrderDetail as d
	join Sales.SalesOrderHeader as h
	on d.SalesOrderID = h.SalesOrderID
where h.OrderDate between '20140301' and '20140331'
group by TerritoryID
order by TerritoryID

--Checking April 2014 selling - Very low revenue comparing to March
--the company sells a few of Bikes = 1.086
select ProductSubcategoryID,
	UnitPriceDiscount,
	sum(OrderQty) as TotalQtyOrdered
from Sales.SalesOrderDetail as d
	join Sales.SalesOrderHeader as h
	on d.SalesOrderID = h.SalesOrderID
	join Production.Product as p
	on d.ProductID = p.ProductID
where h.OrderDate between '20140401' and '20140430'
group by ProductSubcategoryID, UnitPriceDiscount
order by ProductSubcategoryID

--Orders in April 2014 - where do the orders go to? - 2.684 orders for US+Canada; 2.618 orders for Europe+Australia
select TerritoryID,
	count(*) as noOfOrdersByTerritory
from Sales.SalesOrderDetail as d
	join Sales.SalesOrderHeader as h
	on d.SalesOrderID = h.SalesOrderID
where h.OrderDate between '20140401' and '20140430'
group by TerritoryID
order by TerritoryID


