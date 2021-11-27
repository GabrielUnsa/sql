/*
	Creacion de disparadores ( trigger ) en PSQl
*/
--Punto 1
create trigger tg_valida_domicilio2 before insert or update on suppliers
for each row execute procedure fng_valida_proveedores2();

create or replace function fng_valida_proveedores2() returns trigger as
$$
declare
dir_new text;
begin
dir_new:= upper(new.address||new.city||new.country);
if (select count(*) from suppliers where trim(upper(companyname))=trim(upper(new.companyname)) and trim(upper(address))||trim(upper(city))||trim(upper(country))=trim(dir_new)) = 1 then
	Raise exception 'Ya existe un proveedor con este nombre o direccion';
end if;
return new;
end;
$$ language plpgsql;

--Punto 2
create trigger tg_cantidades before insert on orderdetails
for each row execute procedure fng_valida_cantidad();

create or replace function fng_valida_cantidad() returns trigger as
$$
declare
stock integer;
begin
select unitsinstock into stock from products where productid = new.productid;
if stock < new.quantity then
	Raise Exception 'Falta Stock';
end if;
return new;
end;
$$ language plpgsql;


--Punto 3
create trigger tg_actualizar_decrementa before insert on orderdetails
for each row execute procedure fng_actualiza();
create or replace function fng_actualiza() returns trigger as
$$
begin
 update products set unitsinstock=unitsinstock-new.quantity where products.productid=new.productid;
 return new;
end;
$$ language plpgsql;


create trigger tg_actualizar_incrementa before delete on orderdetails
for each row execute procedure fng_actualiza2();
create or replace function fng_actualiza2() returns trigger as
$$
begin
 update products set unitsinstock=unitsinstock+old.quantity where products.productid=old.productid;
 return old;
end;
$$ language plpgsql;

create trigger tg_actualiza_actualiza before update on orderdetails
for each row execute procedure fng_actualiza3();
create or replace function fng_actualiza3() returns trigger as
$$
begin
	update products set unitsinstock=(unitsinstock+old.quantity)-new.quantity where products.productid=old.productid;
	return new;
end;
$$ language plpgsql;

--Punto 4
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
--Punto 5
create or replace function fn_columna() returns void as
$$
declare
cad text;
begin
cad:='alter table orders add column cant_art integer not null';
execute cad;
cad:='alter table orders add column imp_total numeric not null;';
execute cad;
end;
$$ language plpgsql;


create trigger tg_redund_detalles before delete orderdetails
for each row execute procedure fn_redundancia1();

create or replace function fn_redundancia1() returns trigger as
$$
begin
	update orders set cant_art=orders.cant_art-old.quantity where orders.orderid = old.orderid;
	update orders set imp_total=orders.imp_total-(old.unitprice*old.quantity-old.discount) where orders.orderid = old.orderid;
end;
$$ language plpgsql;


create trigger tg_detalles before insert orderdetails
for each row execute procedure fn_redundancia2();

create or replace function fn_redundancia2() returns trigger as
$$
begin
	update orders set cant_art=cant_art+new.quantity where orders.orderid = new.orderid;
	update orders set imp_total=imp_total+(new.unitprice*new.quantity-new.discount) where orders.orderid = new.orderid;
end;
$$ language plpgsql;

create trigger tg_detalles before update orderdetails
for each row execute procedure fn_redundancia3();

create or replace function fn_redundancia3() returns trigger as
$$
begin
	update orders set cant_art=cant_art+old.quantity-new.quantity where orders.orderid = new.orderid;
	update orders set imp_total=imp_total-(old.unitprice*old.quantity-old.discount)+(new.unitprice*new.quantity-new.discount) where orders.orderid = new.orderid;
end;
$$ language plpgsql;
