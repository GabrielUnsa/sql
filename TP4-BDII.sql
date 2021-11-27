--Punto 1
Select customerid, companyname,COUNT(*) over (partition by contacttitle), contacttitle from customers order by 3 desc;

--Punto 2
SELECT date_part('month',orderdate), 
		COUNT(orderid) AS cant_ordenes, 
		SUM(COUNT(orderid)) OVER (order by date_part('month',orderdate))
FROM orders 
WHERE date_part('year',orderdate)='1997' 
GROUP BY date_part('month',orderdate)
ORDER BY 1 ASC;

--Punto 3
SELECT employeeid, 
	   trim(firstname||lastname) as Nombre_Apellido,salary,
	   avg(salary) over (),rank() over (order by salary desc) 
FROM employees;

--Punto 4
SELECT employeeid, 
	   trim(firstname||lastname) as Nombre_Apellido,
	   salary as salario,
	   avg(salary) over () as promedio,
	   rank() over (order by salary desc),
	   salary - avg(salary) over () as prom_sal
FROM employees;

--Punto 5
SELECT customerid,
	   companyname,
	   COUNT(*) as Cantidad_Ordenes,
	   avg(COUNT(orderid)) over()
FROM orders INNER JOIN customers using(customerid)
WHERE date_part('year',orderdate)='1997'
group by 1,2
order by 2;	   

--Punto 6
Create table customersnew(
						customerid	 			integer 	not null,
						firstname				varchar(50)	not null,
						lastname				varchar(50)	not null,
						address1				varchar(50)	not null,
						address2				varchar(50),
						city					varchar(50)	not null,
						state					varchar(50),
						zip 					integer,
						country					varchar(50)	not null,
						region 					smallint,
						email					varchar(50)	not null,
						phone					varchar(50)	not null,
						creditcardtype			integer 	not null,
						creditcard				varchar(50)	not null,
						creditcardexpiration 	varchar(50)	not null,
						username				varchar(50)	not null,
						password				varchar(50)	not null,
						age						smallint,
						income					integer,
						gender					varchar(1)
						
);

INSERT INTO customersnew select * from customers;

--Punto 7	
select customerid,
	   firstname,
	   lastname,
	   country,
	   state,
	   COUNT(*) over (partition by country),
	   COUNT(*) over (partition by state)
from customersnew
order by 4;
--Punto 8
select customerid,
	   firstname,
	   lastname,
	   country,
	   state,
	   estado,
	   COUNT(*) over (partition by country) as pais,
	   rank() over (order by estado desc)
from customersnew inner join (select customerid,COUNT(*) over (partition by state) as estado from customersnew) as  w using (customerid)
where country='US'
order by 7 asc;


select customerid,
	   firstname,
	   lastname,
	   country,
	   state,
	   estado,
	   rank() over (order by pais,estado desc)
from customersnew 
inner join (select customerid,
   				   COUNT(*) over (partition by state) as estado,
   				   COUNT(*) over (partition by country) as pais 
				   from customersnew) as  w 
using (customerid)
order by 7 asc;

select customerid,
	   firstname,
	   lastname,
	   country
	   state,
	   count(*) over (partition by country,state) as cantidad,
	   rank() over (partition by state order by customerid desc) as ranking
from customersnew
where country='US';

--Punto 9

DELETE FROM customersnew 
USING (
select customerid
from customersnew inner join (
select customerid,
	   COUNT(*) over (partition by state) as estado,
	   COUNT(*) over (partition by country) as pais 
from customersnew) as q using (customerid)
where estado > 10 and pais > 10
) as p
where customersnew.customerid=p.customerid;
-- VEAMOS QUE NOS DEVUELVE
select customerid
from customersnew inner join (
select customerid,
	   COUNT(*) over (partition by state) as estado,
	   COUNT(*) over (partition by country) as pais 
from customersnew) as q using (customerid)
where estado <= 10 and pais <= 10; 

DELETE FROM customersnew AS c 
WHERE c.customerid NOT IN

Delete from customersnew 
where customerid not in (
select * from (
select customerid,
	   firstname,
	   lastname,
	   country,
	   state,
	   count(*) over (partition by state) as cantidad,
	   rank() over (partition by state order by customerid desc) as ranking
from customersnew 
where country='US'	    
) as t
where ranking < 11 );

