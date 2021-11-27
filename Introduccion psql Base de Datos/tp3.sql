--1. Insertar en la tabla region la nueva Región: Noroeste Argentino con el ID nro 5.

INSERT INTO region (regionid,regiondescription) VALUES (5,'Noroeste Argentino');
SELECT * FROM region AS r

--2. Insertar en la tabla territories al menos 5 territorios de la nueva región utilizando la sintaxis multirow de insert.

INSERT INTO territories 
VALUES ('00112','Salta',5),('00113','Tucuman',5),('00114','Jujuy',5),('00115','Chaco',5),('00116','Santiago del Estero',5);
SELECT * FROM territories AS t
--3. Crear una nueva tabla tmpterritories con los siguientes atributos:
--territoryid
--territorydescription
--regionid
--regiondescription
CREATE TABLE tmpterritories(
	territoyid CHARACTER VARYING (20),
	territorydescription CHARACTER VARYING (50),
	regionid INTEGER,
	regiondescription CHARACTER VARYING (50)
);
--4. Mediante la sintáxis INSERT .. SELECT llenar la tabla del punto 3 combinando información de las tablas región y territories.

INSERT INTO tmpterritories SELECT t.territoryid,t.territorydescription,t.regionid,r.regiondescription
                             FROM territories AS t INNER JOIN region AS r ON r.regionid = t.regionid
--5. Agregar dos columnas, a la tabla customers, donde se almacene, en forma redundante:
--ordersquantity: con la cantidad de órdenes del cliente en cuestión
--ordersamount : el importe total de las órdenes realizadas
---Mediante comandos UPDATE...FROM actualizar las columnas agregadas
ALTER TABLE customers ADD COLUMN ordersquantity INTEGER, add column ordersamount NUMERIC(10,2)

SELECT c.*,(SELECT COUNT(orderid) FROM orders as o WHERE c.customerid=o.customerid)AS cant,
(SELECT SUM(total) FROM orders AS o WHERE c.customerid=o.customerid) AS amount FROM customers AS c 

UPDATE customers AS c SET ordersquantity=(SELECT COUNT(orderid)FROM orders AS o1 WHERE o1.customerid=c.customerid),
ordersamount=(SELECT SUM(total) FROM orders AS o2 WHERE c.customerid=o2.customerid) FROM orders as o WHERE c.customerid=o.customerid

-- 6.Comparar los resultados obtenidos para la/s consulta/s del ejercicio 5, con los que pudrieran
--obtenerse mediante subconsultas

SELECT 
	c.customerid,
	ordersquantity,
	ordersamount,
	(SELECT COUNT(orderid) 
	FROM orders as o WHERE c.customerid=o.customerid)AS cant,
	(SELECT SUM(total) FROM orders AS o 
	 WHERE c.customerid=o.customerid) AS amount FROM customers AS c ORDER BY 1

--7. Generar un trigger que, utilizando los comandos UPDATE…FROM, mantenga esta redundancia bajo control.
CREATE OR REPLACE FUNCTION fn_redundancia_or() RETURNS TRIGGER AS $$
BEGIN
	IF (TG_OP ='INSERT') THEN
		UPDATE customers as c SET ordersquantity=ordersquantity+1,
		ordersamount=ordersamount+NEW.total
		WHERE c.customerid=NEW.customerid;
	ELSIF (TG_OP='UPDATE') THEN 
		IF (NEW.customerid<> OLD.customerid) THEN
			--restarle al cliente old
			UPDATE customers AS c SET ordersquntity=ordersquantity-1,
			ordersamount=ordersamount-OLD.total
			WHERE c.customerid=OLD.customerid;
			--sumarle al cliente new
			UPDATE customers AS c SET ordersquntity=ordersquantity+1,
			ordersamount=ordersamount+NEW.total
			WHERE c.customerid=NEW.customerid;
		END IF;
	ELSIF (TG_OP='DELETE')THEN
		UPDATE customers AS c SET ordersquantity=orderquantity-1,
		ordersamount=ordersamount-OLD.total
		WHERE c.customerid=OLD.customerid;
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tg_redundancia BEFORE INSERT OR DELETE ON orders 
FOR EACH ROW EXECUTE PROCEDURE fn_redundancia_or();
--8. Programar una función que permita eliminar todo el historial de órdenes de un cliente pasado como parámetro,
-- utilizando DELETE…USING.

CREATE OR REPLACE FUNCTION fn_elimina_ordenc(clienteid VARCHAR(5))
RETURNS void AS $$
BEGIN
	DELETE FROM orders USING customers WHERE customers.customerid=clienteid; 
END;
$$ LANGUAGE plpgsql;
