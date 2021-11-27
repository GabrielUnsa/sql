--1. Listar id, apellido y nombre de los cliente ordenados en un ranking decreciente, según la función 
--del contacto (dentro de la empresa) contacttitle.

SELECT c.customerid,c.companyname FROM customers AS c ORDER BY c.contacttitle DESC 

--2. Mostrar, por cada mes del año 1997, la cantidad de ordenes generadas, junto a la cantidad de ordenes
-- acumuladas hasta ese mes (inclusive).

SELECT date_part('month',o.orderdate)AS mes,COUNT(DISTINCT(o.orderid))AS cant_ordenes,
SUM(COUNT(DISTINCT(o.orderid)))OVER(ORDER BY date_part('month',o.orderdate))AS total
FROM orders AS o 
WHERE date_part('year',o.orderdate)='1997'
GROUP BY mes

--3. Listar todos los empleados agregando las columnas: salario, salario promedio, ranking según salario.
--no funciona
SELECT e.employeeid,e.lastname,e.firstname,e.salary,(((e.comission_pct/100)*e.salary)+e.salary) AS salario, 
avg(((e.comission_pct/'100')*e.salary)+e.salary)OVER () as salariopro,
RANK() OVER (ORDER BY 5) FROM employees AS e 

--4. Listar los mismos datos del punto anterior agregando una columna con la diferencia de salario con el promedio.

--5. Mostrar un ranking de clientes: id y nombre de la compañía con las cantidades de órdenes 
--del año 1997 del cliente, junto al promedio de órdenes del mismo año (de todos los clientes)

SELECT c.customerid,c.companyname,COUNT(o.orderid) AS cant FROM customers AS c 
INNER JOIN orders AS o ON o.customerid = c.customerid
WHERE date_part('year',o.orderdate)='1997'
GROUP BY c.customerid

--Crear una base llamada DellStore2 y restaurarla (el backup estará en la plataforma). Posteriormente, realizar las siguientes operaciones:
--6. Crear una nueva tabla customersnew con la misma estructura y datos que customers pero sin claves foráneas

--7. De la nueva tabla listar customerid, firstname, lastname, country, state y la cuenta de cuantos hay por country y state.

--8. De la nueva tabla listar registros de ‘US’ proyectando las columnas: customerid, firstname, lastname, country, state, la cuenta de cuantos hay por country y state y el ranking dentro de cada partición según customerid.

--9. Eliminar filas de la nueva tabla procurando que por cada country/state no hayan más de 10 clientes