--Trabajo Practico N°3
--Punto 1
INSERT INTO region VALUES('5','Noroeste Argentino');
--Punto 2
INSERT INTO territories VALUES ('1008','Puna','5'),('1009','Chaco','5'),('1010','Valle de Lerma','5'),('1011','Cordillerana','5'),('1012','Sierras','5');
--Punto 3
CREATE TABLE tmpterritories(
			     territoryid	 		VARCHAR(20),
			     territorydescription	VARCHAR(50),
			     regionid				INTEGER NOT NULL,
			     regiondescription		VARCHAR(50) 
			);
--Punto 4
INSERT INTO tmpterritories SELECT territoryid,territorydescription,regionid,regiondescription FROM territories inner join region using (regionid);
--Punto 5
ALTER TABLE customers ADD COLUMN ordersquantity integer;
ALTER TABLE customers ADD COLUMN ordersamount numeric(10,2);

UPDATE customers SET ordersquantity=q.cant, ordersamount=q.total 
FROM (SELECT customerid,COUNT(*)::INTEGER AS cant,fn_total(customerid) AS total 
			FROM orders 
			GROUP BY 1) AS q 
WHERE customers.customerid=q.customerid;

CREATE OR REPLACE FUNCTION fn_total(varchar) RETURNS NUMERIC AS
$$
DECLARE
id ALIAS FOR $1;
total numeric:=0;
r record;
BEGIN
 FOR r IN (SELECT * FROM orderdetails INNER JOIN orders USING(orderid) WHERE customerid=id) LOOP
	total:=total+(r.quantity*r.unitprice-r.discount);
 END LOOP;
 RETURN total;
END;
$$ LANGUAGE PLPGSQL;

--Punto 6

SELECT * FROM (SELECT DISTINCT(customerid),SUM(quantity*unitprice-discount),cant_ordenes(customerid)
			FROM orders INNER JOIN orderdetails using(orderid) group by 1) AS p
INNER JOIN (SELECT customerid,COUNT(*)::INTEGER AS cant,fn_total(customerid) AS total 
			FROM orders 
			GROUP BY 1) AS q USING (customerid);
			
CREATE OR REPLACE FUNCTION cant_ordenes(varchar) RETURNS INTEGER AS
$$
DECLARE
id ALIAS FOR $1;
cant INTEGER;
BEGIN
SELECT COUNT(*)::INTEGER INTO cant FROM orders WHERE customerid=id;
RETURN cant;
END;
$$ LANGUAGE PLPGSQL;			

--Punto 7
CREATE TRIGGER tg_controla BEFORE INSERT OR UPDATE OR DELETE orderdetails
FOR EACH ROW EXECUTE PROCEDURE fn_controla();

CREATE OR REPLACE fn_controla() RETURNS TRIGGER AS
$$
BEGIN
	IF TG_OP = 'INSERT' THEN
	UPDATE customers SET ordersamount=ordersamount+(new.quantity*new.unitprice-new.discount)
	FROM orders
	WHERE customerid=orders.customerid;
	ELSIF TG_OP ='DELETE' THEN
	UPDATE customers SET ordersamount=ordersamount-(old.quantity*old.unitprice-old.discount)
	FROM orders
	WHERE customerid=orders.customerid;
	ELSIF TG_OP='UPDATE' THEN
	UPDATE customers SET ordersamount=ordersamount-(old.quantity*old.unitprice-old.discount)+(new.quantity*new.unitprice-new.discount)
	FROM orders
	WHERE customerid=orders.customerid;
	END IF;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER tg_control BEFORE INSERT OR DELETE OR UPDATE orders
FOR EACH ROW EXECUTE PROCEDURE fn_control();

CREATE OR REPLACE fn_control() RETURNS TRIGGER AS
$$
BEGIN
	IF TG_OP='INSERT' THEN
	UPDATE customers SET ordersquantity=ordersquantity+1 
	WHERE customersid=new.customersid;
	ELSIF TG_OP='UPDATE' THEN
		IF old.customersid <> new.customersid THEN
			UPDATE customers SET ordersquantity=ordersquantity-1 
			WHERE customersid=old.customersid; 
			UPDATE customers SET ordersquantity=ordersquantity+1 
			WHERE customersid=new.customersid; 
		END IF;
	ELSIF TG_OP='DELETE' THEN
	UPDATE customers SET ordersquantity=ordersquantity-1 
	WHERE customersid=old.customersid;
	END IF;
END;
$$LANGUAGE PLPGSQL;

CREATE TRIGGER tg_pcontrol BEFORE UPDATE OR DELETE products
FOR EACH ROW EXECUTE PROCEDURE fn_pcontrol();

CREATE OR REPLACE fn_pcontrol() RETURNS TRIGGER AS
$$
BEGIN
	IF TG_OP='UPDATE' THEN
		UPDATE orderdetails SET unitprice=new.unitprice;
	ELSE
		DELETE FROM orderdetails WHERE unitprice=0;
	END IF;
END;
$$ LANGUAGE PLPGSQL;
--Punto 8
/*Mal falta relacion*/
CREATE OR REPLACE FUNCTION fn_elimina(varchar) RETURNS VOID AS
$$
DECLARE
id ALIAS FOR $1;
BEGIN
    DELETE FROM orders USING customers WHERE customerid=customers.customerid AND customerid=id;
END;
$$ LANGUAGE PLPGSQL;

CREATE OR REPLACE FUNCTION fn_elimina(varchar) RETURNS void AS
$$
DECLARE
id ALIAS FOR $1;
BEGIN
with t as (SELECT orderid 
		   from orders 
		   where upper(trim(customerid))=upper(trim(id))
		   )
delete from orderdetails using t where orderdetails.orderid=t.orderid;

with t as (SELECT orderid 
		   from orders 
		   where upper(trim(customerid))=upper(trim(id))
		   )
delete from orders using t where orders.orderid=t.orderid;
END;
$$ LANGUAGE PLPGSQL;--47,787 winner in time

CREATE FUNCTION fn_delete(id varchar) returns void as $$
declare r record;
begin
	for r in (select orderid from orders where upper(trim(customerid))=upper(trim(id)))loop
		delete from orderdetails as od where od.orderid=r.orderid; 
		delete from orders as od where od.orderid=r.orderid;
	end loop;
 end;
$$ language plpgsql; --50.617 luzer on timer

/*
delete from orderdetails where orderid in(SELECT orderid from orders where upper(trim(customerid))=upper(trim(id)));
delete from orders where orderid in(SELECT orderid from orders where upper(trim(customerid))=upper(trim(id)));	*/

-------------------------------------------------------------------------------------------------------------
UPDATE customers SET ordersquantity=fn_ordenes(customerid) WHERE customerid IN (SELECT customerid FROM customers);
--SubConsulta
update customers set ordersquantity=(select count(*)::integer from orders where orders.customerid=customers.customerid);
CREATE OR REPLACE FUNCTION fn_ordenes(varchar)RETURNS INTEGER AS
$$
DECLARE
id ALIAS FOR  $1;
cant INTEGER;
BEGIN
SELECT COUNT(*)::INTEGER INTO cant FROM orders WHERE TRIM(UPPER(customerid))=TRIM(UPPER(id));
RETURN cant;
END;
$$ LANGUAGE PLPGSQL;

