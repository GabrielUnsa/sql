Parte 1
Ejercicio 1
Primero modificaremos:
#shared_preload_libraries = '' por shared_preload_libraries = 'pg_stat_statements' #habilitamos la libreria
Agregaremos las sentencias:
pg_stat_statements.max=100
pg_stat_statements.track=top
pg_stat_statements.track_utility=false

Ejercicio 2
Activamos en dellstore2
\c dellstore2
create extension pg_stat_statements;

Ejercicio 3
1 select * from customers;
2 select customerid from customers order by 1;
3 select rank() over (partition by region) from customers;
4 create or replace function unico(varchar)returns integer as
$$
declare
id alias for $1;
newid integer:=0;
begin
select row into newid from (select row_number() over (order by customerid) as row, customerid from customers) as t where t.customerid=id;
return newid+(20000);
end;
$$ language plpgsql;
5 select unico(username) from customers;
6 select * from products,reorder;
7 CREATE TABLE suppliers (
						 supplierid   integer not null,
						 companyname  varchar(40),
						 contactname  varchar(30),
						 contacttitle varchar(30),
						 address      varchar(60),
						 city         varchar(15),
						 region       varchar(15),
						 postalcode   varchar(10),
						 country      varchar(15),
						 phone        varchar(24),
						 fax          varchar(24),
						 homepage     text
						);
8 insert into reorder (prod_id,date_low,quan_low,supplierid) select prod_id,now() as date_low, cast(random()*999+1 as integer) as quan_low, cast(random()*28+1 as integer) as supplierid from products;
9 COPY suppliers TO '/home/gabriel/Documentos/database/dellstore2_customers' CSV DELIMITER '|' HEADER;
10 create tablespace ds3 location '/home/gabriel/Documentos/tablespace';

Ejercicio 4
SELECT
(total_time / 1000 / 60)::numeric(11,6) as total_minutes,
(total_time/calls/1000/60)::numeric(11,6) as average_time_minutes,
rows as total_rows,
rows/calls as average_rows,
calls,
query
FROM pg_stat_statements
order by 1 desc
limit 5;

Parte 2
Punto 1
1.- select * from orders where customerid > 10000;
2.- explain analyze select * from orders where customerid > 10000;
Punto 2
1.- select * from orders where customerid > 15000;
2.- explain analyze select * from orders where customerid > 15000;
Punto 3
1.- select orderid, customerid from orders where customerid > 100;
2.- explain analyze select orderid, customerid from orders where customerid > 100;
Punto 4
1.- select * from orders where orderid=100;
2.- explain analyze select * from orders where orderid=100;
Punto 5
1.- select orders.*,customers.lastname, customers.firstname from orders inner join customers using (customerid)
		where cutomers.lastname ='CMLIDQ';
2.- explain analyze select orders.*,customers.lastname, customers.firstname from orders inner join customers using (customerid)
										 where cutomers.lastname ='CMLIDQ';
Punto 6
1.- select * from products where title like 'P%';
2.- explain analyze select * from products where title like 'P%';
Punto 7
1.- select * from products where actor='PENELOPE NEWMAN';
2.- explain analyze select * from products where actor='PENELOPE NEWMAN';
Punto 8
a.-
1- update products set price=(
	 select t.prod_id, t.price-t.price*0.10 as newprice
	 from (products
	 inner join categories using (category)) as t
	 where t.categoryname = 'Sports' and t.prod_id =products.prod_id);
2.- explain analyze update products set price=(
	 									select t.prod_id, t.price-t.price*0.10 as newprice
	 									from (products
	 									inner join categories using (category)) as t
	 									where t.categoryname = 'Sports' and t.prod_id =products.prod_id);
b.-
1.- update products set price=t.newprice
		from(select prod_id,.price-.price*0.10 as newprice
		 			from (products
		 			inner join categories using (category)
	 			 ) as t
		where where t.categoryname = 'Sports' and t.prod_id =products.prod_id;
2.- explain analyze update products set price=t.newprice
										from(select prod_id,.price-.price*0.10 as newprice
		 											from (products
		 											inner join categories using (category)
	 			 								) as t
										where where t.categoryname = 'Sports' and t.prod_id =products.prod_id;

Analizaremos las consultas con y sin indices: (Analisis de Consultas)
1.- Puesto que la consulta es muy simple no se puede desarrollar de otra forma
asi que solo necesitameros analizar con y sin indices
Es recomendable hacer siempre antes de una prueba un analyze

select * from orders where customerid > 10000;
select * from orders where customerid not between 0 and 10000;
select max(customerid) from orders;
select * from orders where customerid between 10001 and 20000;

Primer Caso:
select * from orders where customerid > 10000;
analyze orders;
explain analyze select * from orders where customerid > 10000;
Con indices:
QUERY PLAN
---------------------------------------------------------------------------------------------------------
Seq Scan on orders  (cost=0.00..244.00 rows=6084 width=30) (actual time=0.034..9.463 rows=6084 loops=1)
Filter: (customerid > 10000)
Rows Removed by Filter: 5916
Planning time: 0.446 ms
Execution time: 13.357 ms

Sin Indices:
begin;
drop index ix_order_custid;
explain analyze select * from orders where customerid > 10000;
rollback;
Resultados:
QUERY PLAN
---------------------------------------------------------------------------------------------------------
Seq Scan on orders  (cost=0.00..244.00 rows=6084 width=30) (actual time=0.029..6.056 rows=6084 loops=1)
Filter: (customerid > 10000)
Rows Removed by Filter: 5916
Planning time: 0.231 ms
Execution time: 9.340 ms

Segundo Caso:
con la funcion max veremos cual es el maximo valor que tiene castomerid
select max(customerid) from orders;
Leugo lu usaremos (el valor) para implementar en la consulta
select * from orders where customerid between 10001 and 20000;

Analisis de max luego a los resultados se sumara el tiempo de esta funcion de manera que tengamos el tiempo total real
explain analyze select max(customerid) from orders;
Con Indices:
QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------------------------
Result  (cost=0.34..0.35 rows=1 width=4) (actual time=0.033..0.033 rows=1 loops=1)
InitPlan 1 (returns $0)
->  Limit  (cost=0.29..0.34 rows=1 width=4) (actual time=0.027..0.028 rows=1 loops=1)
->  Index Only Scan Backward using ix_order_custid on orders  (cost=0.29..702.24 rows=11998 width=4) (actual time=0.025..0.025 rows=1 loops=1)
Index Cond: (customerid IS NOT NULL)
Heap Fetches: 1
Planning time: 0.259 ms
Execution time: 0.075 ms

Sin Indices:
begin;
drop index ix_order_custid;
explain analyze select max(customerid) from orders;
rollback;
QUERY PLAN
----------------------------------------------------------------------------------------------------------------
Aggregate  (cost=244.00..244.01 rows=1 width=4) (actual time=14.991..14.992 rows=1 loops=1)
->  Seq Scan on orders  (cost=0.00..214.00 rows=12000 width=4) (actual time=0.015..9.169 rows=12000 loops=1)
Planning time: 0.287 ms
Execution time: 15.043 ms
(4 filas)

Ahora analizaremos la sentencia en si:
explain analyze select * from orders where customerid between 10001 and 20000;s
Con indices:
QUERY PLAN
---------------------------------------------------------------------------------------------------------
Seq Scan on orders  (cost=0.00..274.00 rows=6084 width=30) (actual time=0.022..8.933 rows=6084 loops=1)
Filter: ((customerid >= 10001) AND (customerid <= 20000))
Rows Removed by Filter: 5916
Planning time: 0.462 ms
Execution time: 11.979 ms
Real Time= 11.979 + 0.075=12.054

sin indices:
begin;
drop index ix_order_custid;
explain analyze select * from orders where customerid between 10001 and 20000;
rollback;
QUERY PLAN
---------------------------------------------------------------------------------------------------------
Seq Scan on orders  (cost=0.00..274.00 rows=6083 width=30) (actual time=0.016..5.309 rows=6084 loops=1)
Filter: ((customerid >= 10001) AND (customerid <= 20000))
Rows Removed by Filter: 5916
Planning time: 0.255 ms
Execution time: 7.288 ms
Real time = 7.888+15.043=22.9321

Tercer Caso:
Con indices:
explain analyze select * from orders where customerid not between 0 and 10000;
QUERY PLAN
---------------------------------------------------------------------------------------------------------
Seq Scan on orders  (cost=0.00..274.00 rows=6084 width=30) (actual time=0.016..5.040 rows=6084 loops=1)
Filter: ((customerid < 0) OR (customerid > 10000))
Rows Removed by Filter: 5916
Planning time: 0.304 ms
Execution time: 6.948 ms


Sin Indices:
begin;
drop index ix_order_custid;
explain analyze select * from orders where customerid not between 0 and 10000;
rollback;
QUERY PLAN
---------------------------------------------------------------------------------------------------------
Seq Scan on orders  (cost=0.00..274.00 rows=6085 width=30) (actual time=0.020..5.256 rows=6084 loops=1)
Filter: ((customerid < 0) OR (customerid > 10000))
Rows Removed by Filter: 5916
Planning time: 0.319 ms
Execution time: 7.211 ms


2.-
select * from orders where customerid > 15000;
select * from orders where customerid not between 0 and 15000;
select max(customerid) from orders;
select * from orders where customerid between 15001 and 20000;

analyze orders;
Con indices:
explain analyze select * from orders where customerid > 15000;
Resutados:
QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------
Bitmap Heap Scan on orders  (cost=55.62..187.26 rows=3011 width=30) (actual time=1.665..6.129 rows=3016 loops=1)
Recheck Cond: (customerid > 15000)
Heap Blocks: exact=94
->  Bitmap Index Scan on ix_order_custid  (cost=0.00..54.87 rows=3011 width=0) (actual time=1.542..1.542 rows=3016 loops=1)
Index Cond: (customerid > 15000)
Planning time: 0.855 ms
Execution time: 8.822 ms

Sin indices:
analyze orders
begin;
drop index ix_order_custid;
explain analyze select * from orders where customerid > 15000;
rollback;
Resultados:
QUERY PLAN
---------------------------------------------------------------------------------------------------------
Seq Scan on orders  (cost=0.00..244.00 rows=3011 width=30) (actual time=0.022..4.769 rows=3016 loops=1)
Filter: (customerid > 15000)
Rows Removed by Filter: 8984
Planning time: 0.320 ms
Execution time: 6.201 ms

Segundo Caso:
MAX()
Con indice:
explain analyze select max(customerid) from orders;
QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------------------------
Result  (cost=0.34..0.35 rows=1 width=4) (actual time=0.029..0.029 rows=1 loops=1)
InitPlan 1 (returns $0)
->  Limit  (cost=0.29..0.34 rows=1 width=4) (actual time=0.023..0.023 rows=1 loops=1)
->  Index Only Scan Backward using ix_order_custid on orders  (cost=0.29..702.24 rows=11998 width=4) (actual time=0.021..0.021 rows=1 loops=1)
Index Cond: (customerid IS NOT NULL)
Heap Fetches: 1
Planning time: 0.237 ms
Execution time: 0.068 ms

Sin Indice:
begin;
drop index ix_order_custid;
explain analyze select max(customerid) from orders;
rollback;
QUERY PLAN
-----------------------------------------------------------------------------------------------------------------
Aggregate  (cost=244.00..244.01 rows=1 width=4) (actual time=21.419..21.420 rows=1 loops=1)
->  Seq Scan on orders  (cost=0.00..214.00 rows=12000 width=4) (actual time=0.014..16.044 rows=12000 loops=1)
Planning time: 0.231 ms
Execution time: 21.474 ms

Select()
Con indice:
explain analyze select * from orders where customerid between 15001 and 20000;
QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------
Bitmap Heap Scan on orders  (cost=63.15..202.31 rows=3011 width=30) (actual time=0.428..2.217 rows=3016 loops=1)
Recheck Cond: ((customerid >= 15001) AND (customerid <= 20000))
Heap Blocks: exact=94
->  Bitmap Index Scan on ix_order_custid  (cost=0.00..62.39 rows=3011 width=0) (actual time=0.393..0.393 rows=3016 loops=1)
Index Cond: ((customerid >= 15001) AND (customerid <= 20000))
Planning time: 0.360 ms
Execution time: 3.834 ms
Time Real: 0.068 + 3.834 = 3.902;

Sin Indice:
begin;
drop index ix_order_custid;
explain analyze select * from orders where customerid between 15001 and 20000;
rollback;
QUERY PLAN
---------------------------------------------------------------------------------------------------------
Seq Scan on orders  (cost=0.00..274.00 rows=3010 width=30) (actual time=0.017..6.610 rows=3016 loops=1)
Filter: ((customerid >= 15001) AND (customerid <= 20000))
Rows Removed by Filter: 8984
Planning time: 0.289 ms
Execution time: 7.600 ms
Time Real: 7.600 + 21.474 = 29.074

Tercer Caso:
Con indice:
explain analyze select * from orders where customerid not between 0 and 15000;
QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------
Bitmap Heap Scan on orders  (cost=60.67..199.83 rows=3011 width=30) (actual time=0.391..2.055 rows=3016 loops=1)
Recheck Cond: ((customerid < 0) OR (customerid > 15000))
Heap Blocks: exact=94
->  BitmapOr  (cost=60.67..60.67 rows=3011 width=0) (actual time=0.326..0.326 rows=0 loops=1)
->  Bitmap Index Scan on ix_order_custid  (cost=0.00..4.29 rows=1 width=0) (actual time=0.006..0.006 rows=0 loops=1)
Index Cond: (customerid < 0)
->  Bitmap Index Scan on ix_order_custid  (cost=0.00..54.87 rows=3011 width=0) (actual time=0.318..0.318 rows=3016 loops=1)
Index Cond: (customerid > 15000)
Planning time: 0.382 ms
Execution time: 3.040 ms


Sin Indice:
begin;
drop index ix_order_custid;
explain analyze select * from orders where customerid not between 0 and 15000;
rollback;
QUERY PLAN
---------------------------------------------------------------------------------------------------------
Seq Scan on orders  (cost=0.00..274.00 rows=3012 width=30) (actual time=0.017..6.178 rows=3016 loops=1)
Filter: ((customerid < 0) OR (customerid > 15000))
Rows Removed by Filter: 8984
Planning time: 0.256 ms
Execution time: 7.151 ms

3.-
select orderid,customerid from orders where customerid not between 0 and 100;
select orderid, customerid from orders where customerid > 100;
select max(customerid) from orders;
select orderid, customerid from orders where customerid between 101 and 20000;
analyze orders;
Primer Caso:
con indices:
explain analyze select orderid,customerid from orders where customerid not between 0 and 100;
QUERY PLAN
----------------------------------------------------------------------------------------------------------
Seq Scan on orders  (cost=0.00..274.00 rows=11933 width=8) (actual time=0.016..8.116 rows=11938 loops=1)
Filter: ((customerid < 0) OR (customerid > 100))
Rows Removed by Filter: 62
Planning time: 0.260 ms
Execution time: 12.145 ms

sin indices:
begin;
drop index ix_order_custid;
explain analyze select orderid,customerid from orders where customerid not between 0 and 100;
rollback;
QUERY PLAN
----------------------------------------------------------------------------------------------------------
Seq Scan on orders  (cost=0.00..274.00 rows=11933 width=8) (actual time=0.021..9.936 rows=11938 loops=1)
Filter: ((customerid < 0) OR (customerid > 100))
Rows Removed by Filter: 62
Planning time: 0.253 ms
Execution time: 16.860 ms

Segundo Caso:
con indices:
explain analyze select orderid, customerid from orders where customerid > 100;
QUERY PLAN
-----------------------------------------------------------------------------------------------------------
Seq Scan on orders  (cost=0.00..244.00 rows=11933 width=8) (actual time=0.028..13.577 rows=11938 loops=1)
Filter: (customerid > 100)
Rows Removed by Filter: 62
Planning time: 0.446 ms
Execution time: 21.033 ms

sin indices:
begin;
drop index ix_order_custid;
explain analyze select orderid,customerid from orders where customerid > 100;
rollback;
QUERY PLAN
----------------------------------------------------------------------------------------------------------
Seq Scan on orders  (cost=0.00..244.00 rows=11933 width=8) (actual time=0.016..7.495 rows=11938 loops=1)
Filter: (customerid > 100)
Rows Removed by Filter: 62
Planning time: 0.199 ms
Execution time: 11.294 ms

Tercer Caso:
MAX()
Con indices:
explain analyze select max(customerid) from orders;
QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------------------------
Result  (cost=0.34..0.35 rows=1 width=4) (actual time=0.050..0.051 rows=1 loops=1)
InitPlan 1 (returns $0)
->  Limit  (cost=0.29..0.34 rows=1 width=4) (actual time=0.041..0.042 rows=1 loops=1)
->  Index Only Scan Backward using ix_order_custid on orders  (cost=0.29..702.24 rows=11998 width=4) (actual time=0.038..0.038 rows=1 loops=1)
Index Cond: (customerid IS NOT NULL)
Heap Fetches: 1
Planning time: 0.398 ms
Execution time: 0.112 ms

Sin indices:
begin;
drop index ix_order_custid;
explain analyze select max(customerid) from orders;
rollback;
QUERY PLAN
----------------------------------------------------------------------------------------------------------------
Aggregate  (cost=244.00..244.01 rows=1 width=4) (actual time=10.989..10.990 rows=1 loops=1)
->  Seq Scan on orders  (cost=0.00..214.00 rows=12000 width=4) (actual time=0.014..5.229 rows=12000 loops=1)
Planning time: 0.227 ms
Execution time: 11.046 ms

SELECT()
Con indices:
explain analyze select orderid, customerid from orders where customerid between 101 and 20000;
QUERY PLAN
-----------------------------------------------------------------------------------------------------------
Seq Scan on orders  (cost=0.00..274.00 rows=11933 width=8) (actual time=0.022..10.858 rows=11938 loops=1)
Filter: ((customerid >= 101) AND (customerid <= 20000))
Rows Removed by Filter: 62
Planning time: 0.410 ms
Execution time: 16.425 ms
Real Time: 16.425 + 0.112 = 16.537

Sin indeces:
begin;
drop index ix_order_custid;
explain analyze select orderid, customerid from orders where customerid between 101 and 20000;
rollback;
QUERY PLAN
----------------------------------------------------------------------------------------------------------
Seq Scan on orders  (cost=0.00..274.00 rows=11932 width=8) (actual time=0.017..9.117 rows=11938 loops=1)
Filter: ((customerid >= 101) AND (customerid <= 20000))
Rows Removed by Filter: 62
Planning time: 0.208 ms
Execution time: 13.525 ms
Real Time= 13.525 + 11.046 = 24.571
4.-
select * from orders where orderid=100;
Con Indices
explain analyze select * from orders where orderid=100;
QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------
Index Scan using orders_pkey on orders  (cost=0.29..8.30 rows=1 width=30) (actual time=33.112..33.115 rows=1 loops=1)
Index Cond: (orderid = 100)
Planning time: 0.275 ms
Execution time: 33.168 ms

Sin Indices:
begin;
alter table orderlines drop constraint fk_orderid;
alter table orders drop constraint orders_pkey;
explain analyze select * from orders where orderid=100;
rollback;
QUERY PLAN
----------------------------------------------------------------------------------------------------
Seq Scan on orders  (cost=0.00..244.00 rows=1 width=30) (actual time=6.870..15.233 rows=1 loops=1)
Filter: (orderid = 100)
Rows Removed by Filter: 11999
Planning time: 64.614 ms
Execution time: 15.283 ms

5.-
select orders.*, customers.lastname, customers.firstname from orders inner join customers using (customerid) where customers.lastname = 'CMLIDQ';
select orders.*, customers.lastname, customers.firstname from orders,customers where orders.customerid=customers.customerid and customers.lastname = 'CMLIDQ';
select orders.*, customers.lastname, customers.firstname from orders inner join customers on orders.customerid=customers.customerid where customers.lastname = 'CMLIDQ';
select orders.*, t.lastname, t.firstname from orders inner join (select customerid, lastname,firstname from customers where lastname = 'CMLIDQ') as t on orders.customerid=t.customerid;

Primer caso:
con indices:
begin;
create index ix_lastname on customers(lastname);
explain analyze select orders.*, customers.lastname, customers.firstname from orders inner join customers using (customerid) where customers.lastname = 'CMLIDQ';
rollback;
QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------
Nested Loop  (cost=0.57..16.62 rows=1 width=48) (actual time=0.062..0.062 rows=0 loops=1)
->  Index Scan using ix_lastname on customers  (cost=0.29..8.30 rows=1 width=22) (actual time=0.061..0.061 rows=0 loops=1)
Index Cond: ((lastname)::text = 'CMLIDQ'::text)
->  Index Scan using ix_order_custid on orders  (cost=0.29..8.30 rows=1 width=30) (never executed)
Index Cond: (customerid = customers.customerid)
Planning time: 59.805 ms
Execution time: 0.127 ms

sin indices:
begin;
alter table orders drop constraint fk_customerid;
alter table cust_hist drop constraint fk_cust_hist_customerid;
alter table customers drop constraint customers_pkey;
drop index ix_order_custid;
explain analyze select orders.*, customers.lastname, customers.firstname from orders inner join customers using (customerid) where customers.lastname = 'CMLIDQ';
rollback;
QUERY PLAN
------------------------------------------------------------------------------------------------------------------
Hash Join  (cost=729.10..988.11 rows=1 width=48) (actual time=8.983..8.983 rows=0 loops=1)
Hash Cond: (orders.customerid = customers.customerid)
->  Seq Scan on orders  (cost=0.00..214.00 rows=12000 width=30) (actual time=0.013..0.013 rows=1 loops=1)
->  Hash  (cost=729.09..729.09 rows=1 width=22) (actual time=8.960..8.960 rows=0 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 4kB
->  Seq Scan on customers  (cost=0.00..729.09 rows=1 width=22) (actual time=8.958..8.958 rows=0 loops=1)
Filter: ((lastname)::text = 'CMLIDQ'::text)
Rows Removed by Filter: 20087
Planning time: 0.328 ms
Execution time: 9.040 ms

Segundo caso:
con indices:
begin;
create index ix_lastname on customers(lastname);
explain analyze select orders.*, customers.lastname, customers.firstname from orders,customers where orders.customerid=customers.customerid and customers.lastname = 'CMLIDQ';
rollback;
QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------
Nested Loop  (cost=0.57..16.62 rows=1 width=48) (actual time=0.057..0.057 rows=0 loops=1)
->  Index Scan using ix_lastname on customers  (cost=0.29..8.30 rows=1 width=22) (actual time=0.055..0.055 rows=0 loops=1)
Index Cond: ((lastname)::text = 'CMLIDQ'::text)
->  Index Scan using ix_order_custid on orders  (cost=0.29..8.30 rows=1 width=30) (never executed)
Index Cond: (customerid = customers.customerid)
Planning time: 0.786 ms
Execution time: 0.120 ms

sin indices:
begin;
alter table orders drop constraint fk_customerid;
alter table cust_hist drop constraint fk_cust_hist_customerid;
alter table customers drop constraint customers_pkey;
drop index ix_order_custid;
explain analyze select orders.*, customers.lastname, customers.firstname from orders,customers where orders.customerid=customers.customerid and customers.lastname = 'CMLIDQ';
rollback;
QUERY PLAN
------------------------------------------------------------------------------------------------------------------
Hash Join  (cost=729.10..988.11 rows=1 width=48) (actual time=6.438..6.438 rows=0 loops=1)
Hash Cond: (orders.customerid = customers.customerid)
->  Seq Scan on orders  (cost=0.00..214.00 rows=12000 width=30) (actual time=0.016..0.016 rows=1 loops=1)
->  Hash  (cost=729.09..729.09 rows=1 width=22) (actual time=6.410..6.410 rows=0 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 4kB
->  Seq Scan on customers  (cost=0.00..729.09 rows=1 width=22) (actual time=6.409..6.409 rows=0 loops=1)
Filter: ((lastname)::text = 'CMLIDQ'::text)
Rows Removed by Filter: 20087
Planning time: 0.349 ms
Execution time: 6.495 ms

Tercero caso:
con indices:
begin;
create index ix_lastname on customers(lastname);
explain analyze	select orders.*, customers.lastname, customers.firstname from orders inner join customers on orders.customerid=customers.customerid where customers.lastname = 'CMLIDQ';
rollback;
QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------
Nested Loop  (cost=0.57..16.62 rows=1 width=48) (actual time=0.056..0.056 rows=0 loops=1)
->  Index Scan using ix_lastname on customers  (cost=0.29..8.30 rows=1 width=22) (actual time=0.055..0.055 rows=0 loops=1)
Index Cond: ((lastname)::text = 'CMLIDQ'::text)
->  Index Scan using ix_order_custid on orders  (cost=0.29..8.30 rows=1 width=30) (never executed)
Index Cond: (customerid = customers.customerid)
Planning time: 0.785 ms
Execution time: 0.120 ms

sin indices:
begin;
alter table orders drop constraint fk_customerid;
alter table cust_hist drop constraint fk_cust_hist_customerid;
alter table customers drop constraint customers_pkey;
drop index ix_order_custid;
explain analyze	select orders.*, customers.lastname, customers.firstname from orders inner join customers on orders.customerid=customers.customerid where customers.lastname = 'CMLIDQ';
rollback;
QUERY PLAN
------------------------------------------------------------------------------------------------------------------
Hash Join  (cost=729.10..988.11 rows=1 width=48) (actual time=6.325..6.325 rows=0 loops=1)
Hash Cond: (orders.customerid = customers.customerid)
->  Seq Scan on orders  (cost=0.00..214.00 rows=12000 width=30) (actual time=0.015..0.015 rows=1 loops=1)
->  Hash  (cost=729.09..729.09 rows=1 width=22) (actual time=6.300..6.300 rows=0 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 4kB
->  Seq Scan on customers  (cost=0.00..729.09 rows=1 width=22) (actual time=6.298..6.298 rows=0 loops=1)
Filter: ((lastname)::text = 'CMLIDQ'::text)
Rows Removed by Filter: 20087
Planning time: 0.346 ms
Execution time: 6.379 ms

Cuarto caso:
con indices:
begin;
create index ix_lastname on customers(lastname);
explain analyze select orders.*, t.lastname, t.firstname from orders inner join (select customerid, lastname,firstname from customers where lastname = 'CMLIDQ') as t on orders.customerid=t.customerid;
rollback;
QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------
Nested Loop  (cost=0.57..16.62 rows=1 width=48) (actual time=0.045..0.045 rows=0 loops=1)
->  Index Scan using ix_lastname on customers  (cost=0.29..8.30 rows=1 width=22) (actual time=0.043..0.043 rows=0 loops=1)
Index Cond: ((lastname)::text = 'CMLIDQ'::text)
->  Index Scan using ix_order_custid on orders  (cost=0.29..8.30 rows=1 width=30) (never executed)
Index Cond: (customerid = customers.customerid)
Planning time: 0.675 ms
Execution time: 0.097 ms

sin indices:
begin;
alter table orders drop constraint fk_customerid;
alter table cust_hist drop constraint fk_cust_hist_customerid;
alter table customers drop constraint customers_pkey;
drop index ix_order_custid;
explain analyze select orders.*, t.lastname, t.firstname from orders inner join (select customerid, lastname,firstname from customers where lastname = 'CMLIDQ') as t on orders.customerid=t.customerid;
rollback;
QUERY PLAN
------------------------------------------------------------------------------------------------------------------
Hash Join  (cost=729.10..988.11 rows=1 width=48) (actual time=6.504..6.504 rows=0 loops=1)
Hash Cond: (orders.customerid = customers.customerid)
->  Seq Scan on orders  (cost=0.00..214.00 rows=12000 width=30) (actual time=0.014..0.014 rows=1 loops=1)
->  Hash  (cost=729.09..729.09 rows=1 width=22) (actual time=6.480..6.480 rows=0 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 4kB
->  Seq Scan on customers  (cost=0.00..729.09 rows=1 width=22) (actual time=6.478..6.478 rows=0 loops=1)
Filter: ((lastname)::text = 'CMLIDQ'::text)
Rows Removed by Filter: 20087
Planning time: 0.361 ms
Execution time: 6.562 ms

6.-
select * from products where title like 'P%';
con indices:
begin;
create index ix_title on products(title);
explain analyze select * from products where title like 'P%';
rollback;
QUERY PLAN
-----------------------------------------------------------------------------------------------------
Seq Scan on products  (cost=0.00..223.00 rows=1 width=49) (actual time=2.547..2.547 rows=0 loops=1)
Filter: ((title)::text ~~ 'P%'::text)
Rows Removed by Filter: 10000
Planning time: 0.512 ms
Execution time: 2.587 ms


sin indices:
explain analyze select * from products where title like 'P%';
QUERY PLAN
-----------------------------------------------------------------------------------------------------
Seq Scan on products  (cost=0.00..223.00 rows=1 width=49) (actual time=2.574..2.574 rows=0 loops=1)
Filter: ((title)::text ~~ 'P%'::text)
Rows Removed by Filter: 10000
Planning time: 0.364 ms
Execution time: 2.635 ms


7.-
select * from products where actor='PENELOPE NEWMAN';
con indices:
begin;
create index ix_actor on products(actor);
explain analyze select * from products where actor='PENELOPE NEWMAN';
rollback;
QUERY PLAN
--------------------------------------------------------------------------------------------------------------------
Index Scan using ix_actor on products  (cost=0.29..8.30 rows=1 width=49) (actual time=0.109..0.111 rows=1 loops=1)
Index Cond: ((actor)::text = 'PENELOPE NEWMAN'::text)
Planning time: 0.565 ms
Execution time: 0.163 ms

sin indices:
explain analyze select * from products where actor='PENELOPE NEWMAN';
QUERY PLAN
-----------------------------------------------------------------------------------------------------
Seq Scan on products  (cost=0.00..223.00 rows=1 width=49) (actual time=0.032..2.851 rows=1 loops=1)
Filter: ((actor)::text = 'PENELOPE NEWMAN'::text)
Rows Removed by Filter: 9999
Planning time: 0.180 ms
Execution time: 2.888 ms

8.-
Opciones:
select t.prod_id, t.price-t.price*0.10 as newprice from (products inner join categories using (category)) as t where t.categoryname = 'Sports';
select prod_id, price-price*0.10 from products,categories where products.category = categories.category and categories.categoryname='Sports';
select t.prod_id,t.price-t.price*0.10 from(products inner join categories on products.category = categories.category) as t where t.categoryname='Sports';
select tp.prod_id,tp.price-tp.price*0.10 from(products inner join (select category from categories where categoryname='Sports') as t on products.category = t.category ) as tp;

Nos hacen falta:
en products y categories
index en products :ix_prod_category
				 category	:categories_pkey
Falta
en categories categoryname:	ix_categoryname

/*SubConsulta*/
begin;
create index ix_categoryname on categories(categoryname);
explain analyze update products as p set price=(select t.price-t.price*0.10
													 								 			from (products inner join categories using (category)) as t
													 							 	 			where t.categoryname='Sports' and p.prod_id=t.prod_id); /*NO FUNCIONA WHY???*/
rollback;

SubConsultas Con indices:
begin;
create index ix_categoryname on categories(categoryname);
explain analyze update products as p set price=price-price*0.10 where prod_id in (select t.prod_id from (products inner join categories using (category)) as t where t.categoryname = 'Sports');
rollback;
QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------------------------
Update on products p  (cost=135.48..377.02 rows=663 width=76) (actual time=36.079..36.079 rows=0 loops=1)
->  Nested Loop  (cost=135.48..377.02 rows=663 width=76) (actual time=2.948..13.353 rows=625 loops=1)
->  HashAggregate  (cost=135.20..141.83 rows=663 width=16) (actual time=2.890..3.792 rows=625 loops=1)
Group Key: products.prod_id
->  Nested Loop  (cost=13.42..133.54 rows=663 width=16) (actual time=0.228..2.286 rows=625 loops=1)
->  Seq Scan on categories  (cost=0.00..1.20 rows=1 width=10) (actual time=0.014..0.021 rows=1 loops=1)
Filter: ((categoryname)::text = 'Sports'::text)
Rows Removed by Filter: 15
->  Bitmap Heap Scan on products  (cost=13.42..125.71 rows=663 width=14) (actual time=0.210..1.811 rows=625 loops=1)
Recheck Cond: (category = categories.category)
Heap Blocks: exact=104
->  Bitmap Index Scan on ix_prod_category  (cost=0.00..13.26 rows=663 width=0) (actual time=0.185..0.185 rows=1246 loops=1)
Index Cond: (category = categories.category)
->  Index Scan using products_pkey on products p  (cost=0.29..0.35 rows=1 width=55) (actual time=0.008..0.008 rows=1 loops=625)
Index Cond: (prod_id = products.prod_id)
Planning time: 0.911 ms
Execution time: 36.211 ms

begin;
create index ix_categoryname on categories(categoryname);
explain analyze update products as p set price=price-price*0.10 where prod_id in (select prod_id from products,categories where products.category = categories.category and categories.categoryname='Sports');
rollback;
QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------------------------
Update on products p  (cost=142.76..398.16 rows=702 width=76) (actual time=36.675..36.675 rows=0 loops=1)
->  Nested Loop  (cost=142.76..398.16 rows=702 width=76) (actual time=3.028..15.596 rows=625 loops=1)
->  HashAggregate  (cost=142.48..149.50 rows=702 width=16) (actual time=2.975..3.887 rows=625 loops=1)
Group Key: products.prod_id
->  Nested Loop  (cost=13.73..140.72 rows=702 width=16) (actual time=0.254..2.349 rows=625 loops=1)
->  Seq Scan on categories  (cost=0.00..1.20 rows=1 width=10) (actual time=0.016..0.021 rows=1 loops=1)
Filter: ((categoryname)::text = 'Sports'::text)
Rows Removed by Filter: 15
->  Bitmap Heap Scan on products  (cost=13.73..132.50 rows=702 width=14) (actual time=0.232..1.826 rows=625 loops=1)
Recheck Cond: (category = categories.category)
Heap Blocks: exact=110
->  Bitmap Index Scan on ix_prod_category  (cost=0.00..13.55 rows=702 width=0) (actual time=0.202..0.202 rows=1867 loops=1)
Index Cond: (category = categories.category)
->  Index Scan using products_pkey on products p  (cost=0.29..0.35 rows=1 width=55) (actual time=0.012..0.012 rows=1 loops=625)
Index Cond: (prod_id = products.prod_id)
Planning time: 0.839 ms
Execution time: 36.813 ms


begin;
create index ix_categoryname on categories(categoryname);
explain analyze update products as p set price=price-price*0.10 where prod_id in (select t.prod_id from (products inner join categories on products.category = categories.category) as t where t.categoryname='Sports');
rollback;
QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------------------------
Update on products p  (cost=150.01..418.95 rows=740 width=76) (actual time=34.550..34.550 rows=0 loops=1)
->  Nested Loop  (cost=150.01..418.95 rows=740 width=76) (actual time=2.926..13.250 rows=625 loops=1)
->  HashAggregate  (cost=149.72..157.12 rows=740 width=16) (actual time=2.881..3.783 rows=625 loops=1)
Group Key: products.prod_id
->  Nested Loop  (cost=14.02..147.87 rows=740 width=16) (actual time=0.294..2.293 rows=625 loops=1)
->  Seq Scan on categories  (cost=0.00..1.20 rows=1 width=10) (actual time=0.014..0.018 rows=1 loops=1)
Filter: ((categoryname)::text = 'Sports'::text)
Rows Removed by Filter: 15
->  Bitmap Heap Scan on products  (cost=14.02..139.27 rows=740 width=14) (actual time=0.275..1.818 rows=625 loops=1)
Recheck Cond: (category = categories.category)
Heap Blocks: exact=116
->  Bitmap Index Scan on ix_prod_category  (cost=0.00..13.84 rows=740 width=0) (actual time=0.250..0.250 rows=2488 loops=1)
Index Cond: (category = categories.category)
->  Index Scan using products_pkey on products p  (cost=0.29..0.35 rows=1 width=55) (actual time=0.009..0.009 rows=1 loops=625)
Index Cond: (prod_id = products.prod_id)
Planning time: 0.863 ms
Execution time: 34.674 ms

begin;
create index ix_categoryname on categories(categoryname);
explain analyze update products as p set price=price-price*0.10 where prod_id in (select tp.prod_id from(products inner join (select category from categories where categoryname='Sports') as t on products.category = t.category ) as tp);
rollback;
QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------------------------------
Update on products p  (cost=128.24..356.22 rows=625 width=76) (actual time=29.217..29.217 rows=0 loops=1)
->  Nested Loop  (cost=128.24..356.22 rows=625 width=76) (actual time=1.845..10.910 rows=625 loops=1)
->  HashAggregate  (cost=127.95..134.20 rows=625 width=16) (actual time=1.808..2.700 rows=625 loops=1)
Group Key: products.prod_id
->  Nested Loop  (cost=13.13..126.39 rows=625 width=16) (actual time=0.124..1.218 rows=625 loops=1)
->  Seq Scan on categories  (cost=0.00..1.20 rows=1 width=10) (actual time=0.014..0.017 rows=1 loops=1)
Filter: ((categoryname)::text = 'Sports'::text)
Rows Removed by Filter: 15
->  Bitmap Heap Scan on products  (cost=13.13..118.94 rows=625 width=14) (actual time=0.106..0.755 rows=625 loops=1)
Recheck Cond: (category = categories.category)
Heap Blocks: exact=98
->  Bitmap Index Scan on ix_prod_category  (cost=0.00..12.97 rows=625 width=0) (actual time=0.081..0.081 rows=625 loops=1)
Index Cond: (category = categories.category)
->  Index Scan using products_pkey on products p  (cost=0.29..0.35 rows=1 width=55) (actual time=0.008..0.008 rows=1 loops=625)
Index Cond: (prod_id = products.prod_id)
Planning time: 0.968 ms
Execution time: 29.380 ms

Sin indices
begin;
alter table categories drop constraint categories_pkey;
alter table products drop constraint products_pkey;
drop index ix_prod_category;
explain analyze update products as p set price=price-price*0.10 where prod_id in (select t.prod_id from (products inner join categories using (category)) as t where t.categoryname = 'Sports');
rollback;
QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------
Update on products p  (cost=266.05..516.37 rows=663 width=76) (actual time=38.456..38.456 rows=0 loops=1)
->  Hash Semi Join  (cost=266.05..516.37 rows=663 width=76) (actual time=11.664..26.279 rows=625 loops=1)
Hash Cond: (p.prod_id = products.prod_id)
->  Seq Scan on products p  (cost=0.00..210.12 rows=10612 width=55) (actual time=0.027..7.755 rows=10000 loops=1)
->  Hash  (cost=257.76..257.76 rows=663 width=16) (actual time=11.593..11.593 rows=625 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 28kB
->  Hash Join  (cost=1.21..257.76 rows=663 width=16) (actual time=0.043..11.036 rows=625 loops=1)
Hash Cond: (products.category = categories.category)
->  Seq Scan on products  (cost=0.00..210.12 rows=10612 width=14) (actual time=0.008..6.509 rows=10000 loops=1)
->  Hash  (cost=1.20..1.20 rows=1 width=10) (actual time=0.017..0.017 rows=1 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 5kB
->  Seq Scan on categories  (cost=0.00..1.20 rows=1 width=10) (actual time=0.010..0.012 rows=1 loops=1)
Filter: ((categoryname)::text = 'Sports'::text)
Rows Removed by Filter: 15
Planning time: 0.432 ms
Execution time: 39.148 ms

begin;
alter table categories drop constraint categories_pkey;
alter table products drop constraint products_pkey;
drop index ix_prod_category;
explain analyze update products as p set price=price-price*0.10 where prod_id in (select prod_id from products,categories where products.category = categories.category and categories.categoryname='Sports');
rollback;
QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------
Update on products p  (cost=281.34..546.12 rows=702 width=76) (actual time=40.345..40.345 rows=0 loops=1)
->  Hash Semi Join  (cost=281.34..546.12 rows=702 width=76) (actual time=14.086..29.422 rows=625 loops=1)
Hash Cond: (p.prod_id = products.prod_id)
->  Seq Scan on products p  (cost=0.00..222.24 rows=11224 width=55) (actual time=0.022..8.322 rows=10000 loops=1)
->  Hash  (cost=272.56..272.56 rows=702 width=16) (actual time=14.027..14.027 rows=625 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 28kB
->  Hash Join  (cost=1.21..272.56 rows=702 width=16) (actual time=0.040..13.507 rows=625 loops=1)
Hash Cond: (products.category = categories.category)
->  Seq Scan on products  (cost=0.00..222.24 rows=11224 width=14) (actual time=0.008..8.832 rows=10000 loops=1)
->  Hash  (cost=1.20..1.20 rows=1 width=10) (actual time=0.016..0.016 rows=1 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 5kB
->  Seq Scan on categories  (cost=0.00..1.20 rows=1 width=10) (actual time=0.009..0.011 rows=1 loops=1)
Filter: ((categoryname)::text = 'Sports'::text)
Rows Removed by Filter: 15
Planning time: 0.386 ms
Execution time: 40.448 ms

begin;
alter table categories drop constraint categories_pkey;
alter table products drop constraint products_pkey;
drop index ix_prod_category;
explain analyze update products as p set price=price-price*0.10 where prod_id in (select t.prod_id from (products inner join categories on products.category = categories.category) as t where t.categoryname='Sports');
rollback;
QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------
Update on products p  (cost=296.62..575.85 rows=740 width=76) (actual time=38.570..38.570 rows=0 loops=1)
->  Hash Semi Join  (cost=296.62..575.85 rows=740 width=76) (actual time=13.138..27.817 rows=625 loops=1)
Hash Cond: (p.prod_id = products.prod_id)
->  Seq Scan on products p  (cost=0.00..234.37 rows=11837 width=55) (actual time=0.022..7.861 rows=10000 loops=1)
->  Hash  (cost=287.37..287.37 rows=740 width=16) (actual time=13.068..13.068 rows=625 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 28kB
->  Hash Join  (cost=1.21..287.37 rows=740 width=16) (actual time=0.040..12.520 rows=625 loops=1)
Hash Cond: (products.category = categories.category)
->  Seq Scan on products  (cost=0.00..234.37 rows=11837 width=14) (actual time=0.008..8.012 rows=10000 loops=1)
->  Hash  (cost=1.20..1.20 rows=1 width=10) (actual time=0.016..0.016 rows=1 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 5kB
->  Seq Scan on categories  (cost=0.00..1.20 rows=1 width=10) (actual time=0.009..0.011 rows=1 loops=1)
Filter: ((categoryname)::text = 'Sports'::text)
Rows Removed by Filter: 15
Planning time: 0.393 ms

begin;
alter table categories drop constraint categories_pkey;
alter table products drop constraint products_pkey;
drop index ix_prod_category;
explain analyze update products as p set price=price-price*0.10 where prod_id in (select tp.prod_id from(products inner join (select category from categories where categoryname='Sports') as t on products.category = t.category ) as tp);
rollback;
QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------
Update on products p  (cost=250.78..486.67 rows=625 width=76) (actual time=48.239..48.239 rows=0 loops=1)
->  Hash Semi Join  (cost=250.78..486.67 rows=625 width=76) (actual time=17.568..32.516 rows=625 loops=1)
Hash Cond: (p.prod_id = products.prod_id)
->  Seq Scan on products p  (cost=0.00..198.00 rows=10000 width=55) (actual time=0.011..7.679 rows=10000 loops=1)
->  Hash  (cost=242.96..242.96 rows=625 width=16) (actual time=17.521..17.521 rows=625 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 28kB
->  Hash Join  (cost=1.21..242.96 rows=625 width=16) (actual time=0.039..9.715 rows=625 loops=1)
Hash Cond: (products.category = categories.category)
->  Seq Scan on products  (cost=0.00..198.00 rows=10000 width=14) (actual time=0.005..5.282 rows=10000 loops=1)
->  Hash  (cost=1.20..1.20 rows=1 width=10) (actual time=0.016..0.016 rows=1 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 5kB
->  Seq Scan on categories  (cost=0.00..1.20 rows=1 width=10) (actual time=0.010..0.011 rows=1 loops=1)
Filter: ((categoryname)::text = 'Sports'::text)
Rows Removed by Filter: 15
Planning time: 0.477 ms
Execution time: 48.342 ms

/*update from*/
Con Indices:
begin;
create index ix_categoryname on categories(categoryname);
explain analyze update products as p set price=tl.newprice
								from (select t.prod_id, t.price-t.price*0.10 as newprice
											from (products inner join categories using (category)) as t
											where t.categoryname = 'Sports'
								) as tl where p.prod_id=tl.prod_id;
rollback;
QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------------------
Update on products p  (cost=13.41..373.14 rows=625 width=76) (actual time=31.007..31.007 rows=0 loops=1)
->  Nested Loop  (cost=13.41..373.14 rows=625 width=76) (actual time=0.354..10.440 rows=625 loops=1)
->  Nested Loop  (cost=13.13..144.39 rows=625 width=23) (actual time=0.333..2.031 rows=625 loops=1)
->  Seq Scan on categories  (cost=0.00..1.20 rows=1 width=10) (actual time=0.013..0.019 rows=1 loops=1)
Filter: ((categoryname)::text = 'Sports'::text)
Rows Removed by Filter: 15
->  Bitmap Heap Scan on products  (cost=13.13..136.94 rows=625 width=21) (actual time=0.315..1.454 rows=625 loops=1)
Recheck Cond: (category = categories.category)
Heap Blocks: exact=116
->  Bitmap Index Scan on ix_prod_category  (cost=0.00..12.97 rows=625 width=0) (actual time=0.258..0.258 rows=2454 loops=1)
Index Cond: (category = categories.category)
->  Index Scan using products_pkey on products p  (cost=0.29..0.36 rows=1 width=48) (actual time=0.007..0.007 rows=1 loops=625)
Index Cond: (prod_id = products.prod_id)
Planning time: 1.573 ms
Execution time: 31.129 ms

Sin Indices:
begin;
alter table categories drop constraint categories_pkey;
alter table products drop constraint products_pkey;
drop index ix_prod_category;
explain analyze update products as p set price=tl.newprice
								from (select t.prod_id, t.price-t.price*0.10 as newprice
											from (products inner join categories using (category)) as t
											where t.categoryname = 'Sports'
								) as tl where p.prod_id=tl.prod_id;
rollback;
QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------
Update on products p  (cost=262.78..521.21 rows=625 width=76) (actual time=39.558..39.558 rows=0 loops=1)
->  Hash Join  (cost=262.78..521.21 rows=625 width=76) (actual time=15.073..29.263 rows=625 loops=1)
Hash Cond: (p.prod_id = products.prod_id)
->  Seq Scan on products p  (cost=0.00..210.00 rows=10000 width=48) (actual time=0.015..8.376 rows=10000 loops=1)
->  Hash  (cost=254.96..254.96 rows=625 width=23) (actual time=13.962..13.962 rows=625 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 33kB
->  Hash Join  (cost=1.21..254.96 rows=625 width=23) (actual time=0.961..13.493 rows=625 loops=1)
Hash Cond: (products.category = categories.category)
->  Seq Scan on products  (cost=0.00..210.00 rows=10000 width=21) (actual time=0.008..6.400 rows=10000 loops=1)
->  Hash  (cost=1.20..1.20 rows=1 width=10) (actual time=0.016..0.016 rows=1 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 5kB
->  Seq Scan on categories  (cost=0.00..1.20 rows=1 width=10) (actual time=0.010..0.011 rows=1 loops=1)
Filter: ((categoryname)::text = 'Sports'::text)
Rows Removed by Filter: 15
Planning time: 0.465 ms
Execution time: 39.682 ms

Con indices
begin;
create index ix_categoryname on categories(categoryname);
explain analyze update products as p set price=tl.newprice
								from (select prod_id, price-price*0.10 as newprice
											from products,categories
											where products.category = categories.category
											and categories.categoryname='Sports'
								) as tl where p.prod_id=tl.prod_id;
rollback;
QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------------------
Update on products p  (cost=13.41..380.64 rows=625 width=76) (actual time=31.679..31.679 rows=0 loops=1)
->  Nested Loop  (cost=13.41..380.64 rows=625 width=76) (actual time=0.416..11.491 rows=625 loops=1)
->  Nested Loop  (cost=13.13..150.39 rows=625 width=23) (actual time=0.397..2.233 rows=625 loops=1)
->  Seq Scan on categories  (cost=0.00..1.20 rows=1 width=10) (actual time=0.013..0.018 rows=1 loops=1)
Filter: ((categoryname)::text = 'Sports'::text)
Rows Removed by Filter: 15
->  Bitmap Heap Scan on products  (cost=13.13..142.94 rows=625 width=21) (actual time=0.379..1.651 rows=625 loops=1)
Recheck Cond: (category = categories.category)
Heap Blocks: exact=122
->  Bitmap Index Scan on ix_prod_category  (cost=0.00..12.97 rows=625 width=0) (actual time=0.303..0.303 rows=3022 loops=1)
Index Cond: (category = categories.category)
->  Index Scan using products_pkey on products p  (cost=0.29..0.36 rows=1 width=48) (actual time=0.008..0.008 rows=1 loops=625)
Index Cond: (prod_id = products.prod_id)
Planning time: 1.203 ms
Execution time: 31.782 ms

Sin indices
begin;
alter table categories drop constraint categories_pkey;
alter table products drop constraint products_pkey;
drop index ix_prod_category;
explain analyze update products as p set price=tl.newprice
								from (select prod_id, price-price*0.10 as newprice
											from products,categories
											where products.category = categories.category
											and categories.categoryname='Sports'
								) as tl where p.prod_id=tl.prod_id;
rollback;
QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------
Update on products p  (cost=262.78..521.21 rows=625 width=76) (actual time=52.885..52.885 rows=0 loops=1)
->  Hash Join  (cost=262.78..521.21 rows=625 width=76) (actual time=13.024..35.102 rows=625 loops=1)
Hash Cond: (p.prod_id = products.prod_id)
->  Seq Scan on products p  (cost=0.00..210.00 rows=10000 width=48) (actual time=0.013..15.950 rows=10000 loops=1)
->  Hash  (cost=254.96..254.96 rows=625 width=23) (actual time=11.960..11.960 rows=625 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 33kB
->  Hash Join  (cost=1.21..254.96 rows=625 width=23) (actual time=0.929..11.467 rows=625 loops=1)
Hash Cond: (products.category = categories.category)
->  Seq Scan on products  (cost=0.00..210.00 rows=10000 width=21) (actual time=0.008..6.754 rows=10000 loops=1)
->  Hash  (cost=1.20..1.20 rows=1 width=10) (actual time=0.015..0.015 rows=1 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 5kB
->  Seq Scan on categories  (cost=0.00..1.20 rows=1 width=10) (actual time=0.009..0.011 rows=1 loops=1)
Filter: ((categoryname)::text = 'Sports'::text)
Rows Removed by Filter: 15
Planning time: 0.606 ms
Execution time: 52.984 ms

Con indices
begin;
create index ix_categoryname on categories(categoryname);
explain analyze update products as p set price=tl.newprice
								from (select t.prod_id,t.price-t.price*0.10 as newprice
											from(products inner join categories
											on products.category = categories.category) as t
											where t.categoryname='Sports'
								) as tl where p.prod_id=tl.prod_id;
rollback;
QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------------------
Update on products p  (cost=17.68..388.71 rows=659 width=76) (actual time=29.667..29.667 rows=0 loops=1)
->  Nested Loop  (cost=17.68..388.71 rows=659 width=76) (actual time=0.256..10.445 rows=625 loops=1)
->  Nested Loop  (cost=17.39..149.42 rows=659 width=23) (actual time=0.236..2.049 rows=625 loops=1)
->  Seq Scan on categories  (cost=0.00..1.20 rows=1 width=10) (actual time=0.013..0.018 rows=1 loops=1)
Filter: ((categoryname)::text = 'Sports'::text)
Rows Removed by Filter: 15
->  Bitmap Heap Scan on products  (cost=17.39..141.63 rows=659 width=21) (actual time=0.219..1.476 rows=625 loops=1)
Recheck Cond: (category = categories.category)
Heap Blocks: exact=100
->  Bitmap Index Scan on ix_prod_category  (cost=0.00..17.23 rows=659 width=0) (actual time=0.140..0.140 rows=1193 loops=1)
Index Cond: (category = categories.category)
->  Index Scan using products_pkey on products p  (cost=0.29..0.36 rows=1 width=48) (actual time=0.007..0.007 rows=1 loops=625)
Index Cond: (prod_id = products.prod_id)
Planning time: 1.132 ms
Execution time: 29.770 ms


Sin indices
begin;
alter table categories drop constraint categories_pkey;
alter table products drop constraint products_pkey;
drop index ix_prod_category;
explain analyze update products as p set price=tl.newprice
								from (select t.prod_id,t.price-t.price*0.10 as newprice
											from(products inner join categories
											on products.category = categories.category) as t
											where t.categoryname='Sports'
								) as tl where p.prod_id=tl.prod_id;
rollback;
QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------
Update on products p  (cost=291.31..577.93 rows=693 width=76) (actual time=41.481..41.481 rows=0 loops=1)
->  Hash Join  (cost=291.31..577.93 rows=693 width=76) (actual time=12.937..31.290 rows=625 loops=1)
Hash Cond: (p.prod_id = products.prod_id)
->  Seq Scan on products p  (cost=0.00..232.91 rows=11091 width=48) (actual time=0.014..12.543 rows=10000 loops=1)
->  Hash  (cost=282.64..282.64 rows=693 width=23) (actual time=11.894..11.894 rows=625 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 33kB
->  Hash Join  (cost=1.21..282.64 rows=693 width=23) (actual time=0.977..11.394 rows=625 loops=1)
Hash Cond: (products.category = categories.category)
->  Seq Scan on products  (cost=0.00..232.91 rows=11091 width=21) (actual time=0.008..6.789 rows=10000 loops=1)
->  Hash  (cost=1.20..1.20 rows=1 width=10) (actual time=0.016..0.016 rows=1 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 5kB
->  Seq Scan on categories  (cost=0.00..1.20 rows=1 width=10) (actual time=0.009..0.011 rows=1 loops=1)
Filter: ((categoryname)::text = 'Sports'::text)
Rows Removed by Filter: 15
Planning time: 0.423 ms
Execution time: 41.581 ms


Con Indices
begin;
create index ix_categoryname on categories(categoryname);
explain analyze update products as p set price=tl.newprice
								from (select prod_id,price-price*0.10 as newprice
											from products inner join (select category from categories where categoryname='Sports') as t
											on products.category = t.category
								) as tl where p.prod_id=tl.prod_id;
rollback;
QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------------------------
Update on products p  (cost=17.41..369.64 rows=625 width=76) (actual time=25.910..25.910 rows=0 loops=1)
->  Nested Loop  (cost=17.41..369.64 rows=625 width=76) (actual time=0.130..8.972 rows=625 loops=1)
->  Nested Loop  (cost=17.13..142.39 rows=625 width=23) (actual time=0.112..1.550 rows=625 loops=1)
->  Seq Scan on categories  (cost=0.00..1.20 rows=1 width=10) (actual time=0.014..0.019 rows=1 loops=1)
Filter: ((categoryname)::text = 'Sports'::text)
Rows Removed by Filter: 15
->  Bitmap Heap Scan on products  (cost=17.13..134.94 rows=625 width=21) (actual time=0.093..0.977 rows=625 loops=1)
Recheck Cond: (category = categories.category)
Heap Blocks: exact=14
->  Bitmap Index Scan on ix_prod_category  (cost=0.00..16.97 rows=625 width=0) (actual time=0.081..0.081 rows=625 loops=1)
Index Cond: (category = categories.category)
->  Index Scan using products_pkey on products p  (cost=0.29..0.36 rows=1 width=48) (actual time=0.007..0.007 rows=1 loops=625)
Index Cond: (prod_id = products.prod_id)
Planning time: 1.112 ms
Execution time: 26.016 ms

Sin Indices
begin;
alter table categories drop constraint categories_pkey;
alter table products drop constraint products_pkey;
drop index ix_prod_category;
explain analyze update products as p set price=tl.newprice
								from (select prod_id,price-price*0.10 as newprice
											from products inner join (select category from categories where categoryname='Sports') as t
											on products.category = t.category
								) as tl where p.prod_id=tl.prod_id;
rollback;
QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------
Update on products p  (cost=262.78..521.21 rows=625 width=76) (actual time=38.768..38.768 rows=0 loops=1)
->  Hash Join  (cost=262.78..521.21 rows=625 width=76) (actual time=15.568..28.431 rows=625 loops=1)
Hash Cond: (p.prod_id = products.prod_id)
->  Seq Scan on products p  (cost=0.00..210.00 rows=10000 width=48) (actual time=0.010..7.201 rows=10000 loops=1)
->  Hash  (cost=254.96..254.96 rows=625 width=23) (actual time=14.609..14.609 rows=625 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 33kB
->  Hash Join  (cost=1.21..254.96 rows=625 width=23) (actual time=0.872..14.099 rows=625 loops=1)
Hash Cond: (products.category = categories.category)
->  Seq Scan on products  (cost=0.00..210.00 rows=10000 width=21) (actual time=0.005..9.571 rows=10000 loops=1)
->  Hash  (cost=1.20..1.20 rows=1 width=10) (actual time=0.015..0.015 rows=1 loops=1)
Buckets: 1024  Batches: 1  Memory Usage: 5kB
->  Seq Scan on categories  (cost=0.00..1.20 rows=1 width=10) (actual time=0.009..0.011 rows=1 loops=1)
Filter: ((categoryname)::text = 'Sports'::text)
Rows Removed by Filter: 15
Planning time: 0.575 ms
Execution time: 38.869 ms


Parte 3
Ejercicio 1
pgbench ya viene instalado en la versiones 9.4 en adelante
pgbench --help nos podria ayudar a saber como usarlo
Ejercicio 2
psql -c "create database pgbench"
psql -c "create database pgbench_history"
psql -c "create database pgbench_tellers"
psql -c "create database pgbench_accounts"
psql -c "create database pgbench_branches"
Comando de Creacion: pgbench -h localhost -p5432 -U postgres -i -s100 --foreign-key pgbench
Comando de prueba: pgbench -T300 -s3 -c50 pgbench
Primera prueba configuracion normal:
scaling factor: 100
query mode: simple
number of clients: 50
number of threads: 1
duration: 300 s
number of transactions actually processed: 19936
latency average = 752.840 ms
tps = 66.415212 (including connections establishing)
tps = 66.416176 (excluding connections establishing)
Punto b
Primera Modificacion:
max_connections = 200
shared_buffers = 512MB
effective_cache_size = 1536MB
work_mem = 2621kB
maintenance_work_mem = 128MB
min_wal_size = 1GB
max_wal_size = 2GB
checkpoint_completion_target = 0.7
wal_buffers = 16MB
default_statistics_target = 100
scaling factor: 100
query mode: simple
number of clients: 50
number of threads: 1
duration: 300 s
number of transactions actually processed: 39742
latency average = 377.876 ms
tps = 132.318508 (including connections establishing)
tps = 132.320542 (excluding connections establishing)

Segunda Modificacion:
max_connections = 50
shared_buffers = 512MB
effective_cache_size = 1536MB
work_mem = 10485kB
maintenance_work_mem = 128MB
min_wal_size = 1GB
max_wal_size = 2GB
checkpoint_completion_target = 0.7
wal_buffers = 16MB
default_statistics_target = 100
scaling factor: 100
query mode: simple
number of clients: 50
number of threads: 1
duration: 300 s
number of transactions actually processed: 46858
latency average = 320.389 ms
tps = 156.060156 (including connections establishing)
tps = 156.062548 (excluding connections establishing)

--NOTAS
--select * from imformation_schema.columns where "tangle_name"='suppliers' /*Una buena anotacion*/
/*
* Una buena comparacion para realizar las eficiencias de las consutas tenemos que:
1° ver todas las opciones que se puede realizar la subconsulta.
2° crear indices con lo que hacemos la subconsulta
luego analizaremos todos los casos con indices y sin indices
Herramientas
begin;
drop index ix_order_custid;
explain analyze select * from orders where customerid > 10000;
rollback;
*/
