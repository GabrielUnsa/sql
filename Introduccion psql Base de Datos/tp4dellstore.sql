
--Crear una base llamada DellStore2 y restaurarla (el backup estará en la plataforma). Posteriormente, realizar las siguientes operaciones:
--6. Crear una nueva tabla customersnew con la misma estructura y datos que customers pero sin claves foráneas

CREATE TABLE customersnew (
	customerid integer NOT NULL ,
	firstname character varying(50) NOT NULL,
	lastname character varying(50) NOT NULL,
	address1 character varying(50) NOT NULL,
	address2 character varying(50),
	city character varying(50) NOT NULL,
	state character varying(50),
	zip integer,
	country character varying(50) NOT NULL,
	region smallint NOT NULL,
	email character varying(50),
	phone character varying(50),
	creditcardtype integer NOT NULL,
	creditcard character varying(50) NOT NULL,
	creditcardexpiration character varying(50) NOT NULL,
	username character varying(50) NOT NULL,
	password character varying(50) NOT NULL,
	age smallint,
	income integer,
	gender character varying(1)
);

INSERT INTO customersnew SELECT * FROM customers
	
--7. De la nueva tabla listar customerid, firstname, lastname, country, state y la cuenta de cuantos hay por country y state.
SELECT 
	c.customerid,
	c.firstname,
	c.lastname, 
	c.country,
	c."state",COUNT(c.customerid) OVER (PARTITION BY c.country,c."state") AS cantidad
FROM customersnew AS c
ORDER BY c.country 

SELECT * FROM customersnew AS c

--8. De la nueva tabla listar registros de ‘US’ proyectando las columnas: customerid, firstname, lastname, 
--country, state, la cuenta de cuantos hay por country y state y el ranking dentro de cada partición según customerid.

SELECT c.customerid, c.firstname, c.lastname,c.country,c."state",COUNT(c.customerid)OVER (country_state)
AS cant, RANK() OVER (PARTITION BY C."state" ORDER BY c.customerid DESC) AS ranking
  FROM customersnew AS c
WHERE c.country ='US'
WINDOW 
	country_state AS (PARTITION BY c.country,c."state")

--9. Eliminar filas de la nueva tabla procurando que por cada country/state no hayan más de 10 clientes
---- de aqui ------ 
/*
ALTER TABLE customersnew ADD COLUMN ranking INTEGER

UPDATE customersnew  as c SET ranking = t.r 
FROM 
(SELECT customerid,RANK() OVER (PARTITION BY STATE ORDER BY customerid DESC )::INTEGER AS r
FROM customersnew AS c WHERE c.country='US')AS t WHERE c.customerid=t.customerid */


--funciona -----------siiiii
SELECT  * from( SELECT customerid, firstname,lastname,country,c.state,
COUNT(*)OVER (by_state),RANK() OVER (by_state ORDER BY customerid DESC) AS r
 FROM customersnew AS c WHERE c.country='US'
  WINDOW 
 by_state AS (PARTITION BY c.STATE) ) t 
WHERE  t.r<=10

--sentencia q no funciona
DELETE FROM customersnew as c USING (SELECT  * from( SELECT customerid, firstname,lastname,country,c.state,
COUNT(*)OVER (by_state),ranking,RANK() OVER (by_state ORDER BY customerid DESC) AS r
 FROM customersnew AS c WHERE c.country='US'
  WINDOW 
 by_state AS (PARTITION BY c.STATE) ) t 
WHERE  t.r<=10) AS tabla 
WHERE c.customerid<>tabla.customerid
------funciona siiiiii
DELETE FROM customersnew AS c 
WHERE c.customerid NOT IN (
SELECT  customerid from( SELECT customerid, firstname,lastname,country,c.state,
COUNT(*)OVER (by_state),RANK() OVER (by_state ORDER BY customerid DESC) AS r
 FROM customersnew AS c WHERE c.country='US'
  WINDOW 
 by_state AS (PARTITION BY c.STATE) ) t 
WHERE  t.r<=10)
SELECT * FROM customersnew AS c

----- hasta aqui -----
--hay otras funciones como dense_rank() y row_number parecen similares a rank()
/*
CREATE TABLE fruits AS SELECT * FROM (VALUES ('apple'),('applee'),('orange'),('grapes'),('grapes'),('watermelon'))fruits;
SELECT NAME,ROW_NUMBER() OVER (ORDER BY name) FROM fruits;

SELECT customerid,country,state,DENSE_RANK() OVER (PARTITION BY STATE ORDER BY customerid DESC ) 
FROM customers AS c WHERE country='US'

SELECT customerid ,RANK() OVER (PARTITION BY STATE ORDER BY customerid DESC ) FROM customersnew AS c WHERE c.country='US'

DROP FUNCTION fn_c()
CREATE OR REPLACE FUNCTION fn_c() 
RETURNS TABLE (customerid INTEGER,firstname VARCHAR,lastname VARCHAR, country VARCHAR, state VARCHAR, cantidad INTEGER,ranking INTEGER) AS $$
DECLARE
	r record;
BEGIN
FOR r IN (SELECT c.customerid, c.firstname,c.lastname,c.country,c.state,
COUNT(*)OVER (PARTITION BY c.country,c."state")::INTEGER ,RANK() OVER (by_state ORDER BY 1 desc)::INTEGER 
 FROM customersnew AS c WHERE c.country='US'  AND c."state"=r.st
 WINDOW by_state AS (PARTITION BY c.STATE) ) LOOP
 	customerid:=r.customerid;firstname:=r.firstname;lastname:=r.lastname;
 	country:=r.country;STATE:=r.state;cantidad:=r.count;ranking:=rank;
;
 END LOOP;
END;
$$ LANGUAGE plpgsql;
SELECT * FROM fn_c(); --para ver lo q devuleve la funcion
--sentencia que elimina drop function fn_c()
DELETE FROM customersnew WHERE customerid not IN (SELECT customerid FROM fn_c())
SELECT * FROM customersnew AS c
 
INSERT INTO customersnew SELECT * FROM customers
DELETE FROM customersnew

SELECT c.country,c."state",COUNT(c.customerid)AS cant 
FROM customersnew AS c
GROUP BY 1,2
ORDER BY 1 --61 rows

--devuelve por cada contry la cantidad que tenia el grupo -10
CREATE OR REPLACE FUNCTION fn_c1() 
RETURNS TABLE (customerid INTEGER,firstname VARCHAR,lastname VARCHAR, ccountry VARCHAR, state VARCHAR, cantidad integer) AS $$
DECLARE
	r record;num INTEGER;
BEGIN
FOR r IN (select country AS co,c.state as st,COUNT(c.customerid)AS cant FROM customersnew AS c
group by 1,2 ORDER BY 1) LOOP
	num:=r.cant-10;
	RETURN query (
	SELECT 
	c.customerid,c.firstname,
	c.lastname,c.country,c."state",
	COUNT(c.customerid) OVER (PARTITION BY c.country,c."state")::INTEGER AS cant
FROM customersnew AS c
WHERE c.country='US' AND c."state"=r.st
order by 1 LIMIT num);
END LOOP;
END;
$$ LANGUAGE plpgsql;
SELECT * FROM fn_c1();
--debe eliminar lo q devuelve fn_c1
delete from customersnew where customerid in (select * from fn_c1());

-- ej8 funciona prueba
(SELECT c.customerid,country,c.state,
COUNT(*)OVER (by_state),(RANK() OVER (by_state ORDER BY customerid)) AS r
 FROM customersnew AS c WHERE c.country='US'
 WINDOW 
 by_state AS (PARTITION BY c.STATE))AS t INNER JOIN (SELECT cn.customerid, firstname,lastname FROM customersnew AS cn)
 WHERE cn.customerid=t.customerid an 
 */