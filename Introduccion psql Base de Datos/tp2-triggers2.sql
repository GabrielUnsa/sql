--1. Crear un disparador para impedir que ingresen dos proveedores en el mismo domicilio. (tener en cuenta la ciudad y país).
CREATE TRIGGER tg_valida_domicilio BEFORE INSERT OR UPDATE ON suppliers
FOR EACH ROW EXECUTE PROCEDURE fn_valida_pro()

CREATE OR REPLACE FUNCTION fn_valida_pro() RETURNS trigger AS $$
BEGIN
	IF (EXISTS (SELECT companyname AS dir FROM suppliers AS s
	               WHERE TRIM(UPPER(NEW.companyname))=TRIM(UPPER(s.companyname)) AND
	               TRIM(UPPER(NEW.address))=TRIM(UPPER(s.address)) AND
	               TRIM(UPPER(NEW.city))=TRIM(UPPER(s.city)) AND 
	               TRIM(UPPER(NEW.country))=TRIM(UPPER(s.country))
	            )=TRUE) THEN
	            	raise EXCEPTION 'ya existe proveedor con ese nombre';
	            	ELSE RETURN NEW;
	END IF;
END; $$ LANGUAGE plpgsql;

INSERT INTO suppliers (supplierid,companyname,address,city,country)VALUES('1000','Exotic Liquids','49 Gilbert St.','London','UK')
DELETE FROM suppliers WHERE supplierid='1000'

--2. Realizar un disparador que impida incluir en un detalle de orden, cantidades no disponibles.
CREATE TRIGGER tg_valida_cantidad BEFORE INSERT OR UPDATE ON orderdetails
FOR EACH ROW EXECUTE PROCEDURE fn_valida_cantidad();

CREATE OR REPLACE FUNCTION fn_valida_cantidad() RETURNS TRIGGER AS $$
DECLARE 
	stock INTEGER;
BEGIN
	SELECT INTO stock unitsinstock FROM products AS p WHERE productid=NEW.productid;
	IF (NEW.quantity>stock) THEN
		raise EXCEPTION 'NO hay stock';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

INSERT INTO orderdetails
(
	orderid,productid,unitprice,quantity,discount)
VALUES('11111','17','18.00','3','0');

--3. Realizar un disparador que actualice el nivel de stock.
CREATE TRIGGER tg_actualiza_stock BEFORE INSERT or UPDATE OR DELETE ON orderdetails
FOR EACH ROW EXECUTE PROCEDURE fn_actualiza_stock();

DROP TRIGGER 
CREATE OR REPLACE FUNCTION fn_actualiza_stock() RETURNS TRIGGER AS $$
BEGIN
	IF TG_OP ='INSERT' THEN 
		execute fn_act_insert();
	END IF;		
	If TG_OP = 'UPDATE' THEN
		UPDATE products SET unitsinstock = unitsinstock+OLD.quantity-NEW.quantity
		WHERE products.productid=NEW.productid;
		RETURN NEW;
	END IF;
	IF TG_OP='DELETE' THEN
		UPDATE products SET unitsinstock = unitsinstock+OLD.quantity
		WHERE products.productid=OLD.productid;
		RETURN OLD;
	END IF;
END;
$$ LANGUAGE plpgsql;
--para modularizar
CREATE OR REPLACE FUNCTION fn_act_insert() RETURNS TRIGGER AS $$
BEGIN
	update products set unitsinstock=unitsinstock-new.quantity 
		where products.productid=new.productid;
		return new;
END; $$ LANGUAGE plpgsql;
CREATE OR REPLACE FUNCTION fn_act_delete() RETURNS TRIGGER AS $$
BEGIN
	UPDATE products SET unitsinstock = unitsinstock+OLD.quantity
		WHERE products.productid=OLD.productid;
		RETURN OLD;
END;
$$ LANGUAGE plpgsql;

INSERT INTO orderdetails(orderid,productid,unitprice,quantity,discount) VALUES('10248',	'2','12.00','10','0');
DELETE FROM orderdetails WHERE orderid='10248' AND productid='3'
SELECT * FROM orderdetails AS o;
SELECT * FROM products AS p;
UPDATE products set unitsinstock ='17' WHERE productid='2'

--4. Realizar un disparador de auditoría sobre la actualización de datos de los clientes. Se debe almacenar
-- el nombre del usuario la fecha en la que se hizo la actualización, la operación realizada (alta/baja/modificación)
--  y el valor que tenía cada atributo al momento de la operación.
--añadiendo columnas a la tabla customers
ALTER TABLE customers ADD COLUMN usuario VARCHAR (50), add column fecha DATE, add column op_usuario VARCHAR

CREATE TRIGGER tg_auditoria_clientes BEFORE INSERT OR UPDATE OR DELETE ON customers 
FOR EACH ROW EXECUTE PROCEDURE fn_auditoria_clientes();

CREATE TABLE auditoria_customers(
	acustomerid SERIAL PRIMARY KEY,
	customerid VARCHAR,
	operacion VARCHAR,
	fecha TIMESTAMP WITHOUT TIME ZONE,
	companyname VARCHAR,
	usuario VARCHAR
);

CREATE OR REPLACE FUNCTION fn_auditoria_clientes()RETURNS TRIGGER AS $$
BEGIN
	IF (TG_OP = 'DELETE') THEN
		INSERT INTO auditoria_customers(companyname,operacion,fecha,usuario) VALUES (old.companyname,tg_op,now(),current_user);
		return old;
	ELSIF (TG_OP = 'UPDATE') THEN
		INSERT INTO auditoria_customers(companyname,operacion,fecha,usuario) VALUES (new.companyname,tg_op,now(),current_user);
		return new;
	ELSIF (TG_OP = 'INSERT') THEN
		INSERT INTO auditoria_customers(customerid,companyname,operacion,fecha,usuario) VALUES (new.customerid,new.companyname,tg_op,now(),current_user);
		return new;
	END IF;
END;
$$ LANGUAGE plpgsql;

-- Si fuera fonrankey q hacemos???
INSERT INTO customers(customerid,companyname) VALUES('ZZD','garbarino')

DELETE FROM customers WHERE customerid='2727';
DELETE FROM auditoria_customers WHERE acustomerid='1';
SELECT * FROM auditoria_customers AS ac
