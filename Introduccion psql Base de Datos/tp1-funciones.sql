--trabjo practico n°1- Funciones
--1. Crear una función que permita eliminar espacios en blanco innecesarios (trim) de una columna de una tabla. 
--Los nombres de columna y tabla deben ser pasados como parámetros y la función deberá devolver como resultado 
--la cantidad de filas afectadas.

CREATE OR REPLACE FUNCTION fn_trim(columna VARCHAR,tabla VARCHAR)
RETURNS INTEGER AS $$
DECLARE cantidad INTEGER;
BEGIN
	SELECT COUNT(*)FROM tabla WHERE TRIM(columna)=columna INTO cantidad;
	RETURN cantidad;
END;
$$ LANGUAGE plpgsql;
--para probar funcion
SELECT * FROM fn_trim(companyname,customers)

--2. Programar una función que reciba como parámetro un orderid y devuelva una cadena de caracteres (resúmen)
-- con el id, nombre, precio unitario y cantidad de todos los productos incluidos en la orden en cuestión.
-- Ejemplo: orderid = 11077, debería devolver
-- 3-Aniseed Syrup-10.00-4, 60-Camembert Pierrot-34.00-2, 2-Chang-19.00-24,…
CREATE OR REPLACE FUNCTION fn_resumen(num_orden INTEGER)RETURNS text AS $$
DECLARE
	cadena TEXT;
	r record;
BEGIN 
	cadena:='';
	FOR r IN
	(SELECT od.productid, trim(p.productname) AS productname, od.unitprice, od.quantity
	 FROM products AS p inner join orderdetails as od on od.productid= p.productid 
	 WHERE od.orderid=num_orden ) LOOP 
	 cadena:= cadena || r.productid || '-' || r.productname || '-' || r.unitprice || '-' || r.quantity || ','; 
	 	END LOOP;
	  Return substring(cadena,0,LENGTH(cadena));
END;
$$ LANGUAGE plpgsql;
SELECT fn_resumen('10248');
	 
-- 3. Crear una función que muestre por cada detalle de orden, el nombre del cliente, la fecha, la identificación
--  de cada artículo (Id y Nombre), cantidad, importe unitario y subtotal de cada ítem para un intervalo de tiempo 
--  dado por parámetros.

CREATE OR REPLACE FUNCTION fn_venta(f1 DATE,f2 DATE)
RETURNS TABLE (id_orden integer,cliente varchar,ordenfecha DATE,id_producto integer, nom_producto varchar, 
cantidad integer,precio_unitario NUMERIC, subtotal NUMERIC) AS $$
BEGIN
	RETURN QUERY (SELECT o.orderid,c.companyname,o.orderdate,p.productid,p.productname,od.quantity,od.unitprice,
		od.unitprice*od.quantity
		FROM orders AS o INNER JOIN customers AS c ON c.customerid = o.customerid 
		INNER JOIN orderdetails AS od ON od.orderid = o.orderid
		INNER JOIN products AS p ON p.productid = od.productid
		WHERE o.orderdate BETWEEN f1 AND f2);
END;$$ LANGUAGE plpgsql;--703 ms

SELECT * FROM fn_venta('1995-02-24','1997-04-27');

--4. Crear una función para el devolver el total de una orden dada por parámetro.

create or replace function total_orden(num_orden integer) 
RETURNS numeric AS $$
DECLARE total NUMERIC;
BEGIN
	select sum(unitprice*quantity-discount)AS total from orderdetails 
	where orderid=num_orden INTO total;
	RETURN total;
END;
$$ LANGUAGE PLPGSQL;

SELECT * FROM total_orden('10248');
--5. Crear una función donde se muestren todos los atributos de cada Orden junto a Id y Nombre del Cliente 
--y el Empleado que la confeccionó. Mostrar el total utilizando la función del punto 4.

CREATE OR REPLACE FUNCTION fn_ordenes ()
RETURNS TABLE(orderid INTEGER,orderdate DATE,customerid VARCHAR,companyname TEXT,employeeid INTEGER,employee TEXT,
requireddate DATE,shippeddate DATE,shipvia INTEGER,freight NUMERIC,shipname TEXT,shipaddress TEXT,
shipcity VARCHAR,shipregion TEXT,shippostalcode VARCHAR,shipcountry VARCHAR,total_orden NUMERIC) AS $$
DECLARE r record;
BEGIN
	RETURN QUERY (SELECT distinct(o.orderid),o.orderdate,c.customerid,TRIM(c.companyname),o.employeeid,e.lastname || ' ' || e.firstname,
	o.requireddate ,o.shippeddate,o.shipvia ,o.freight,trim(o.shipname),trim(o.shipaddress),o.shipcity,trim(o.shipregion),o.shippostalcode,o.shipcountry,total_orden(o.orderid) 
	FROM customers AS c 
	INNER JOIN orders AS o ON o.customerid = c.customerid 
	INNER JOIN employees AS e ON e.employeeid = o.employeeid
	INNER JOIN orderdetails AS od ON od.orderid = o.orderid 
	INNER JOIN products AS p ON p.productid = od.productid
	);
END;
$$ LANGUAGE plpgsql;
SELECT * FROM fn_ordenes() AS fo

--6. Implementar una función que muestre, por cada mes del año ingresado por parametro, la cantidad de ordenes generada, 
--junto a la cantidad de ordenes acumuladas hasta ese mes (inclusive).
-- pero implementando recorrido con registros.
--version consulta
CREATE OR REPLACE FUNCTION fn_cantidades(anio INTEGER) RETURNS TABLE(mes INTEGER,cantidad INTEGER,acumulado integer) as $$ 
DECLARE 
	r record;
	suma INTEGER;
BEGIN
	suma:=0;
	FOR r IN (SELECT date_part('month',o.orderdate)::INTEGER AS mes,COUNT(o.orderid)::INTEGER AS cantidad
	FROM orders AS o 
	WHERE date_part('year',o.orderdate)=anio
	GROUP BY 1)LOOP
	suma:=suma+r.cantidad;
	mes:=r.mes; cantidad:=r.cantidad ;acumulado:=suma;
	RETURN NEXT ;
	END LOOP;
END;
$$ LANGUAGE plpgsql;
SELECT * FROM fn_cantidades('1998');
--muestra 0 en caso de meses que no tengan ordenes en ese mes
CREATE OR REPLACE FUNCTION  fn_cuenta(anio INTEGER) RETURNS TABLE(mes INTEGER,cantidad INTEGER,acumulado integer) AS $$
DECLARE 
	i INTEGER;
	suma INTEGER;
	cant INTEGER;
BEGIN
	suma:=0;
	FOR i IN 1..12 LOOP 
		SELECT into cant COUNT(orderid) FROM orders AS o 
		WHERE date_part('MONTH',o.orderdate)=i AND date_part('year',o.orderdate)=anio ;
	mes:=i; cantidad:=cant; suma:=suma+cant; acumulado:=suma;
	RETURN NEXT;
	END LOOP;
END;
$$ LANGUAGE plpgsql;
SELECT * FROM fn_cuenta('1998');
CREATE OR REPLACE FUNCTION fn_cantidad() RETURNS SETOF record as $$ 
DECLARE 
	r record;
BEGIN
	FOR r IN (SELECT date_part('month',o.orderdate) AS mes,COUNT(DISTINCT(o.orderid))AS cant_ordenes,
	SUM(COUNT(DISTINCT(o.orderid)))OVER(ORDER BY date_part('month',o.orderdate))AS total
	FROM orders AS o 
	WHERE date_part('year',o.orderdate)='1997'
	GROUP BY mes)LOOP
	RETURN NEXT r;
	END LOOP;
END;
$$ LANGUAGE plpgsql;
SELECT * FROM fn_cantidad()AS(mes DOUBLE PRECISION,cantidad_ordenes BIGINT,subtotal NUMERIC);
--7. Crear una función que permita generar las órdenes de compra necesarias para todos los productos
-- que se encuentran por debajo del nivel de stock, para esto deberá crear una tabla de órdenes de compra 
-- y su correspondiente tabla de detalles.
CREATE OR REPLACE FUNCTION crea_tablas_ordenes()RETURNS void AS $$
BEGIN
	CREATE TABLE ordenes_compra (
	oc_id serial,
	fecha_orden DATE,
	supplerid INTEGER,
	PRIMARY KEY (oc_id),
	FOREIGN KEY (supplerid) REFERENCES suppliers
	);
	create table detalles_oc(
	oc_id integer not null,
	productid integer not null,
	dc_cantidad integer not null,
	primary key(oc_id,productid),
	foreign key (oc_id) references ordenes_compra,
	foreign key (productid) references products); 
END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION fn_ordenes_compra() RETURNS void AS $$
DECLARE 
	lr_reg record;
	li_sup INTEGER:=0;
	li_oc_id INTEGER:=0;
BEGIN
	FOR lr_reg IN (SELECT supplierid,productid,unitsonorder FROM products
	 WHERE unitsinstock<reorderlevel ORDER BY supplierid)LOOP
	 	IF li_sup<>lr_reg.supplierid THEN
	 		li_sup:=lr_reg.supplierid;
	 		INSERT INTO ordenes_compra (fecha_orden,supplerid) VALUES (now(),li_sup)
	 		RETURNING oc_id INTO li_oc_id;
	 	END IF;
	 	INSERT INTO detalles_oc VALUES(li_oc_id,lr_reg.productid,lr_reg.unitsonorder);
	 END LOOP;
END;
$$ LANGUAGE plpgsql;
--algunas sentencias
SELECT fn_ordenes_compra();
SELECT * FROM ordenes_compra AS oc INNER JOIN detalles_oc AS do1 ON do1.oc_id = oc.oc_id
SELECT p.supplierid,p.productid,p.productname,p.reorderlevel,p.unitsonorder,p.unitsinstock
  FROM products AS p WHERE p.unitsinstock<p.reorderlevel
ORDER BY supplierid

SELECT COUNT(distinct(supplierid)) FROM products WHERE unitsinstock<reorderlevel
--8. Crear una función que calcule y despliegue por cada país destino de ordenes (orders.shipcountry) 
--y por un rango de tiempo ingresado por parámetros la cantidad de productos diferentes que se vendieron 
--y la cantidad de clientes diferentes. Ejemplo de salida:

CREATE OR REPLACE FUNCTION fn_resultado (f1 DATE, f2 DATE)
RETURNS TABLE(tbl_shipcountry VARCHAR,cant_productos BIGINT,cant_clientes BIGINT) AS $$
BEGIN
	RETURN query SELECT o.shipcountry,COUNT(DISTINCT(p.productid)),COUNT(DISTINCT(o.customerid)) FROM orders AS o 
	INNER JOIN orderdetails AS od ON o.orderid=od.orderid
	INNER JOIN products AS p ON od.productid=p.productid
	WHERE o.shippeddate BETWEEN f1 AND f2 
	GROUP BY o.shipcountry
	ORDER BY 1;
	RETURN;
END; $$ LANGUAGE plpgsql;

SELECT * FROM fn_resultado('1997-02-24','1997-04-27') AS fr
DROP FUNCTION fn_resultado(date,date);
