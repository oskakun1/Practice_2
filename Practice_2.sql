CREATE DATABASE IF NOT EXISTS opt_db;
USE opt_db;

CREATE TABLE IF NOT EXISTS opt_clients (
    id CHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    surname VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(50) NOT NULL,
    address TEXT NOT NULL,
    status ENUM('active', 'inactive') NOT NULL
);

CREATE TABLE IF NOT EXISTS opt_products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    product_category ENUM('Category1', 'Category2', 'Category3', 'Category4', 'Category5') NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS opt_orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    order_date DATE NOT NULL,
    client_id CHAR(36),
    product_id INT,
    FOREIGN KEY (client_id) REFERENCES opt_clients(id),
    FOREIGN KEY (product_id) REFERENCES opt_products(product_id)
);


explain analyze
select oc.name, oc.surname,
  (select count(oo.order_id)
   from opt_orders oo 
   where oo.client_id = oc.id 
   and oo.order_date > '2021-08-07' 
   and oo.product_id IN 
         (select op.product_id 
          from opt_products op 
          where op.product_id IN 
              (select ooo.product_id 
               from opt_orders ooo 
                 where ooo.client_id = oc.id))) as order_count,
  (select count(op.product_id)
   from opt_orders oo 
   join opt_products op on oo.product_id = op.product_id
   where oo.client_id = oc.id
   and op.product_id IN 
         (select op2.product_id 
          from opt_products op2 
          where op2.product_category = 
               (select op3.product_category 
                from opt_products op3 
                where op3.product_id = op2.product_id))) as product_count,
     (select count(DISTINCT op2.product_category)
     from opt_orders oo2
     join opt_products op2 on oo2.product_id = op2.product_id
     where oo2.client_id = oc.id 
       and op2.product_category IN 
           (select DISTINCT op4.product_category 
            from opt_products op4 
            where op4.product_category = 
                  (select op5.product_category 
                   from opt_products op5 
                   where op5.product_id = oo2.product_id))) as unique_category_count
from opt_clients oc 
where status = 'active'
group by oc.id, oc.name, oc.surname;

create index index_opt_clients on opt_clients (status);
create index index_product_category on opt_products(product_category);
create index index_order_date on opt_orders(order_date);

drop index index_opt_clients on opt_clients;
drop index index_product_category on opt_products;
drop index index_order_date on opt_orders;


explain analyze
with active_clients as (
    select oc.id, oc.name, oc.surname
    from opt_clients oc
    where oc.status = 'active'
),
orders_after_date as (
    select oo.client_id, oo.order_id, oo.product_id
    from opt_orders oo
    where oo.order_date > '2021-08-07'
),
client_products as (
    select oo.client_id, op.product_id, op.product_category
    from opt_orders oo
    join opt_products op on oo.product_id = op.product_id
)
select 
    ac.name, 
    ac.surname,
    (select count(oa.order_id)
     from orders_after_date oa
     where oa.client_id = ac.id) as order_count,
    (select count(distinct cp.product_id)
     from client_products cp
     where cp.client_id = ac.id) as product_count,
    (select count(distinct cp.product_category)
     from client_products cp
     where cp.client_id = ac.id) as unique_category_count
from 
    active_clients ac
group by 
    ac.id, ac.name, ac.surname;
























