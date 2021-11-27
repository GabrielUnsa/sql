--Ejercicio 1
COPY suppliers TO '/home/gabriel/Documentos/database/suppliers_northwind' CSV DELIMITER '|' HEADER;
CREATE TABLE suppliers (
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
copy suppliers from '/home/gabriel/Documentos/database/suppliers_northwind' CSV DELIMITER '|' HEADER;
--Ejercicio 2
/*Probelmas para decir q va en q*/
Modificaciones en DellStore2
alter table customers add column contactname varchar(50);
alter table customers rename column phone to phone_and_fax;
alter table customers alter column address1 type varchar(60);
alter table customers alter column region drop not null;
alter table customers alter column username set not null;


COPY (select unico(customerid) as customerid,
			trim(companyname) as firstname,
			trim(contactname) as lastname,
			trim(address)  as address1,
			'' as address2,
			trim(upper(city))  as city,
			'' as state,
			postalcode(postalcode) as zip,
			trim(country)    as country,
			Runico(region)	 as region,
			'' as email,
			trim(phone)||'|'||trim(fax) as phone_and_fax,
			0 as creditcardtype,
			'' as creditcard,
			'' as creditcardexpiration,
			customerid as username,
			'' as password,
			0 as age,
			0 as income,
			'' as gender,
			trim(contacttitle) as contactname
			from customers) TO '/home/gabriel/Documentos/database/customers_northwind' CSV DELIMITER '|' HEADER;

select customerid from customers where customerid>19997 order by 1;
create or replace function postalcode(varchar) returns integer as
$$
declare
id alias for $1;
postal integer;
begin
if (id between 'A' and 'Z') then
select cast(random()*99999+9999 as integer) into postal;
elsif (id=NULL or id='') then
postal=0;
elsif (id ilike '%-%') then
select replace(id,'-','')::integer into postal;
else
select id::integer into postal;
end if;
return postal;
end;
$$language plpgsql;

create or replace function Runico(varchar) returns smallint as
$$
declare
id alias for $1;
i smallint:=0;
begin
select regionid into i from
(select distinct(region) as region, rank() over(order by region) as regionid from customers) as t
where id=t.region;
return i;
end;
$$language plpgsql;


create or replace function unico(varchar)returns integer as
$$
declare
id alias for $1;
newid integer:=0;
begin
select row into newid from (select row_number() over (order by customerid) as row, customerid from customers) as t where t.customerid=id;
return newid+(20000);
end;
$$ language plpgsql;


copy customers from '/home/gabriel/Documentos/database/customers_northwind' CSV DELIMITER '|' HEADER;
--Ejercicio 3
alter table reorder add column supplierid integer not null;
alter table reorder add primary key (prod_id);
alter table suppliers add primary key (supplierid);
alter table reorder add foreign key (supplierid) references suppliers(supplierid);
--Ejercicio 4 Probar con ventadas
insert into reorder (prod_id,date_low,quan_low,supplierid) select prod_id,now() as date_low, cast(random()*999+1 as integer) as quan_low, cast(random()*28+1 as integer) as supplierid from products;
update reorder set quan_reordered=10*quan_low;
--Ejercicio 5
pg_dump -h localhost -p 5432 -U postgres -v -F t -f "/home/gabriel/Documentos/database/dellstore2.backup" dellstore2
--Ejercicio 6
pg_dump -h localhost -p 5432 -U postgres -v -f "/home/gabriel/Documentos/database/parcial.backup" -d dellstore2 -t customers -t reorder
--Ejercicio 7
El directorio por defecto se realiza con el comando: SHOW data_directory; --Directorio por defecto es /var/lib/postgresql/10/main
Pero no poseemos los privilegios para entrar a este directorio entonces ejecutamos el comando: chmod -R 777 "/var/lib/postgresql/10/main"
El directorio de postgres.conf es: /etc/postgresql/10/main
tampoco contamos con los privilegios para modificarlo aqui que ejecutamos: chmod 777 *
en postgres.conf tiene todos los directorios que necesitamos
--Ejercicio 8
alter role postgres with SUPERUSER;
GRANT ALL PRIVILEGES ON DATABASE northwind TO postgres;
cd /home/gabriel/Documentos
mkdir tablespace
create tablespace ds2 location '/home/gabriel/Documentos/tablespace';
--Ejercicio 9
create database dellstore2marmanillo with tablespace=ds2;
pg_restore -h localhost -p 5432 -U postgres -d dellstore2marmanillo -F t -v "/home/gabriel/Documentos/database/dellstore2.backup"
--Ejecicio 10
/* Para poder modificar el archivo
chmod -R 777 /etc/postgresql/10/main/* */
Vamos al .conf de postgres
buscamos la linea wal_level
se encontrara la sentencia comentada #wal_level = replica
se descmentara y se reemplazara replica por archive
buscamos archive_mode
cambiamos de #archive_mode = off a archive_mode = on
debajo encontraremos #archive_command = '' y cambiamos por archive_command = 'cp %p /home/gabriel/Documentos/Wals/%f'
--Ejercicio 11
Para empezar con todo necesitare creat una carpeta en mis documentos (podria ser en otra direccion mas confiable)
donde guardare todos los backup que realizare.
1° me posicionare en el directorio
cd /home/gabriel/Documentos
2° creare la carpeta donde estaran todos los backup "Wals"
mkdir PBackup
3° Pondre de propietario a postgres a la carpeta creada
chown -R postgres.postgres /home/gabriel/Documentos/PBackup
chmod 700 /home/gabriel/Documentos/PBackup
4° Creare El archivo donde estara el backupfull
touch BackupFull
5° Hare el BackupFull
pg_dumpall -h localhost -p 5432 -U postgres -v -f "/home/gabriel/Documentos/PBackup/BackupFull"
6° Modificare el .conf para hacer el resguardo parcial incremental
Con el super usuario postgres ingresare al directorio "/etc/postgresql/10/main"
buscamos la linea wal_level
se encontrara la sentencia comentada #wal_level = replica
se descmentara y se reemplazara replica por archive
buscamos archive_mode
cambiamos de #archive_mode = off a archive_mode = on
debajo encontraremos #archive_command = '' y cambiamos por archive_command = 'cp %p /home/gabriel/Documentos/PBackup/%f'
7° Realizaremos un nuevo backupfull pero ahora con el perdiodo de tiempo
con el super usuario de postgres ejecutamos: psql -c "select pg_start_backup('20171010',true);"
con el super usuario de postgres ejecutamos: psql -c "select pg_stop_backup();"
con el propietario de la carpeta(en mi caso root) ejecutamos: tar -czvf /home/gabriel/Documentos/Wals/fb_`date +%Y%m%d_%H%M`.tar /var/lib/postgresql/10/main/ --exclude=pg_wal --exclude=postmasterid /*Aqui creamos el .tar donde estaran todos los wal de la fecha*/
/*Nota la unica manera del restaurar en postgresql 10 es copiar los archivos wals que hay en la carpeta archive_status porq no sabemos*/
8° Creamos un realizador de tarea que al terminar el backup lo guarde en la nube a nivel OS.
sudo su
at 00:00
psql -c "select pg_start_backup('20171008',true);"
psql -c "selet pg_stop_backup();"
minusculaEOTmayuscula /*control d*/
at 12:00
cp -r  /var/lib/postgresql/10/main/pg_wal /home/gabriel/Documentos/PBackup/
minusculaEOTmayuscula
at 20:00
cp -r  /var/lib/postgresql/10/main/pg_wal /home/gabriel/Documentos/PBackup/
minusculaEOTmayuscula

Para restaurar
/*Para fijarnos el servicio si esta levantado o no ponemos service postgres status*/
1° Estamos con usuario postgres
sudo su postgres
2° Apagamos el servidor
service postgresql stop
3° Copiamos los wal que qdan
cp -r  /var/lib/postgresql/10/main/pg_wal /home/gabriel/Documentos/Wals/resguardo
4° Booramos todo lo que tenes en main
5° Descomprimimos el tar realizado anteriormente
tar -xvf /home/gabriel/Documentos/Wals/2017101012.tar /var/lib/postgresql/10/main/
6° Eliminamos lo que tenemos en pg_wal
7° Verifiquemos que en Wals esten todos los wal necesarios para la restauracion
8° Copiamos todos los wals que guardamos en el punto 2
cp -r /home/gabriel/Documentos/WalsUltimos/resguardo /var/lib/postgresql/10/main/pg_wal
9° Creamos el archivo recovery.conf
cd /home/gabriel/Documentos/PBackup
mkdir recovery.conf
10° Abrimos recovery.conf y editamos el archivo con las sentencias:
restore_command = 'cp /home/gabriel/Documentos/Wals/%f %p'
11° Iniciamos de nuevo el servidor
service postgresql start

/*NOTAS*/
--tar -cf /home/gabriel/Documentos/PBackup/201710081157.tar /home/gabriel/Documentos/PBackup/
--Comando Debian/Ubuntu
tar -czvf backup.gz --exclude=postmasterid /*Control de procesos de postgres*/
					--execlude=pg_xlog/  /var/lib/postgres/9x/main/
/*me copia todo menos el pg_xlog es decir pg_wal
* En versiones anteriores/posrteriores puede cambiar el directorio (carpeta)
donde postgres guarda los Wals(que recicla)
* Depende del nombre que le hayamos dado cluster
* Claster de base de datos son muchas base de datos con puertos distintos
aqui esta la solucion de los puerto y tambien puede realizar algunas tareas y otras no
los archivos binarios son mas rapidos, cuando creo mas de un cluster doy otros nombres
la remendacion es tomar los puesrtos 5432 main para adelante
tar -czvf /home/gabriel/Documentos/PBackup/201710081300.tar /var/lib/postgres/10/main*/
/*NOTAS Y CONSULTAS*/
/*cd /home/gabriel/Documentos/
mkdir database
rm -r  "archivo/directorio"
chmod -R 777 "/home/gabriel/Documentos/database/"
Ideas para resolver es que transformaba a ascii pero se repiten algunos id,
resolvi sumando al id anterior lo del nuevo id
select bit_length(customerid) as customerid, * from customers;
Lo malo es q se repite algunos ascii por ende optare a poner solo la fila en que esta
create or replace function conv_ascii(varchar)returns integer as
$$
declare
id alias for $1;
ac integer:=0;
begin
ac:=ascii(left(id,1));
ac:=ac+ascii(substr(id,2,1));
ac:=ac+ascii(substr(id,3,1));
ac:=ac+ascii(substr(id,4,1));
ac:=ac+ascii(right(id,1));
return ac;
end;
$$ language plpgsql;

create or replace function unico(varchar)returns integer as
$$
declare
id alias for $1;
newid integer:=0;
begin
select row into newid from (select row_number() over (order by customerid) as row, customerid from customers) as t where t.customerid=id;
return newid+(a);
end;
$$ language plpgsql;
a=select Count(*) from dblink ('dbname=dellstore hostaddr=localhost user=postgres password=GabrielUnsa port=5432','select customerid from customers') as t (customerid integer);
*/
