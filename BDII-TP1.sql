/*
	Creaciones de Funciones en PSQL
*/

-- Punto N°1
create or replace function fn_trim(text,text)
returns integer as
$$
declare
tabla ALIAS FOR $1;
columna ALIAS FOR $2;
cad_ejecutar text;
contador integer;
Begin
	cad_ejecutar:='select Count(*) from 
	(select "' ||columna|| '" from "'||tabla||'" where ( "' ||columna||'" <> trim("' ||columna|| '"))) as o';
	execute cad_ejecutar into contador;
	return contador;
End;
$$ language plpgsql;
select fn_trim('customers','companyname');

--Punto N°2
create or replace function fn_ordenes(integer)
returns text as
$$
declare 
ord ALIAS FOR $1;
r record;
cad text:='';	
begin
	for r in (select orderdetails.productid,trim(productname) as nom,orderdetails.unitprice, quantity 
			  from (orderdetails 
			  inner join products 
			  using (productid)) 
			  where ord=orderid) loop
		cad:= cad || r.productid ||'-'|| r.nom ||'-'|| r.unitprice ||'-'|| r.quantity ||',';
	end loop;
	return substring(cad,0,length(cad));
end;
$$ language plpgsql;

--Punto N°3
create or replace function fn_orden_resumen (num_orden integer) 
returns table (id_producto integer, nom_producto varchar, cantidad integer, subtotal numeric) as $$
begin 
	return query (select products.productid, productname, orderdetails.quantity ,(
									(orderdetails.unitprice*orderdetails.quantity)-orderdetails.discount) as subtotal
from (orderdetails inner join products on orderdetails.productid=products.productid) 
where num_orden=orderid);
end; $$ language plpgsql;

create or replace function resumen (f_inicial date, f_final date) 
returns table (NumOrden integer, NomCliente varchar, fecha date, 
idArticulo integer, NomArticulo varchar, cantidad integer, subtotal numeric) as
$$
BEGIN
	return query (
	select * from (select orders.orderid, customers.companyname, orders.orderdate 
	from customers inner join orders on customers.customerid=orders.customerid) as o,
	fn_orden_resumen(o.orderid) where (o.orderdate between f_inicial and f_final)
	);
END;
$$ LANGUAGE PLPGSQL;

select * from resumen('1995-02-24','1997-04-27');

--Punto N°4
create or replace function total_orden (numorden integer)
returns numeric AS
$$
declare
total numeric;
BEGIN
select SUM((unitprice*quantity)-discount) into total
from orderdetails 
where numorden=orderid;
return total;
END;
$$ LANGUAGE PLPGSQL;

select total_orden('10248');

--Punto N°5
create or replace function empleados() returns table (orderid integer, nom_empleado text) as
$$
begin
	return query (select orders.orderid,trim(firstname || ', '|| lastname) as nom_empleado 
				  from orders 
				  inner join employees using (employeeid));
end;
$$language plpgsql;

create or replace function clientes() returns table (orderid integer,nom_clientes text) as
$$
begin
	return query (select orders.orderid, trim(companyname) as nom_clientes
				  from orders 
				  inner join customers using (customerid)
				  );
end;
$$ language plpgsql;
	
create or replace function ordenes() returns table(orderid integer,customerid varchar,nom_cliente text,employeeid integer,
												   nom_empleado text, ordedate date,total numeric,requireddate date,shippeddate date,
												   shipvia integer, freight numeric, shipname varchar,shipaddress varchar,shipcity varchar,
												   shipregion varchar,shippostalcode varchar,shipcountry varchar)as
$$
begin
	return query (select O.orderid, O.customerid, nom_clientes, O.employeeid, O.nom_empleado, orderdate,total_orden(O.orderid) as total, O.requireddate,
						 O.shippeddate,O.shipvia,O.freight,O.shipname,O.shipaddress,O.shipcity,O.shipregion,O.shippostalcode,O.shipcountry 
				  from (orders inner join empleados() using (orderid)) as O 
				  inner join clientes() 
				  using(orderid)
				  );
end;
$$ language plpgsql; 
select * from ordenes();
-- Punto N°6
--version for
create or replace function fn_orden2( integer)
returns Table (mes integer, cant_ordenes integer,acumulado integer) as
$$
declare
anio alias for $1;
acu integer:=0; 
i integer;
begin
for i in 1..12 loop
mes:=i;
select COUNT(orderid)::integer into cant_ordenes from orders where date_part('year',orderdate)=anio  and date_part('month',orderdate)=i;
acu:=acu+cant_ordenes;
acumulado:=acu;
return next;
end loop;
return;
end;
$$ language plpgsql;
--version registro
create or replace function fn_orden( integer)
returns Table (mes text, cant_ordenes integer,acumulado integer) as
$$
declare
anio alias for $1;
acu integer:=0;
r record; 
begin
for r in (select to_char(orderdate,'tmmonth') as mes, COUNT(orderid) as cant from orders 
		  where date_part('years',orderdate)=anio 
		  group by mes, date_part('month',orderdate) order by date_part('month',orderdate)) loop
acu:=acu+r.cant;
mes:=r.mes; cant_ordenes:=r.cant; acumulado:=acu;
return next;
end loop;
return;
end;
$$ language plpgsql;

--version while
create or replace function fn_orden3( integer)
returns Table (mes integer, cant_ordenes integer,acumulado integer) as
$$
declare
anio alias for $1;
acu integer:=0; 
i integer:=1;
begin
while i < 13 LOOP
mes:=i;
select COUNT(orderid) into cant_ordenes from orders where date_part('years',orderdate)=anio  and date_part('month',orderdate)=i;
acu:=acu+cant_ordenes;
acumulado:=acu;
i:=i+1;
return next;
end LOOP;
return;
end;
$$ language plpgsql;

select to_char(orderdate,'tmmounth') as mes, COUNT(orderid) as cant, sum(orderid) over (order by date_part('month',orderdate)) as acumuladas from orders where date_part('years',orderdate)='1997' group by mes, date_part('month',orderdate) order by date_part('month',orderdate);
--Punto N°7
	create or replace function pedidos () returns void as 
	$$
	declare
	cod_eject text;
	registro record;
	proveedor integer:=0;
	cand integer:=0;
	id integer;
	begin
	/*Creacion de las tablas si no existe Ordenes_Compras*/
	if  (select COUNT(*)  from pg_tables where tablename = 'ordenes_compras' ) = 0 then
		cod_eject := 'Create Table Ordenes_Compras(
													idord serial Not Null,
													ord_fecha timestamp without time zone,
													supplierid integer,
													PRIMARY KEY (idord));
					  Create Table Detalles_OC(
												idord integer not null,
												productid integer,
												doc_cantidad integer not null,
												Primary key (idord,productid),
												foreign key (idord) references Ordenes_Compras,
												foreign key (productid) references products)';
		execute cod_eject;
	end if;	
	/*Realizacion del Punto numero 4*/
	for registro in (select supplierid, productid, reorderlevel from products where unitsinstock < reorderlevel order by supplierid) LOOP
		 if proveedor <> registro.supplierid then
			proveedor:=registro.supplierid;
			cand:=registro.reorderlevel+2;
			insert into Ordenes_Compras (ord_fecha,supplierid)
			values (now() ,proveedor)
			returning idord into id;
		end if;
		insert into Detalles_OC
		values (id,registro.productid,cand);
	end LOOP;
	end;
	$$ language plpgsql;

select pedidos();

--Punto N°8
create or replace function paises(date,date) returns table(pais varchar, productos integer, clientes integer) as
$$
declare 
f_inicio alias for $1;
f_final alias for $2;
begin
return query ( select orders.shipcountry as pais,COUNT(distinct(productid))::integer ,COUNT(distinct(customerid))::integer 
			   from (orders inner join orderdetails using(orderid)) 
			   where orderdate between f_inicio and f_final 
			   group by shipcountry
			 );
end;
$$ language plpgsql;

create or replace function paises(date,date) returns table(pais varchar, productos integer, clientes integer) as
$$
declare
r record;
begin
for r in select orders.shipcountry as pais,COUNT(distinct(productid))::integer as producto,COUNT(distinct(customerid))::integer  as cliente
			   from (orders inner join orderdetails using(orderid)) 
			   where orderdate between f_inicio and f_final 
			   group by shipcountry loop
pais:=r.pais;
productos:=r.producto;
cliente:=r.cliente;
return next r;
end loop;
end;
$$ language plpgsql;
