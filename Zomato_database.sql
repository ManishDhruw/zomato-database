drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'2017-09-22'),
(3,'2017-04-21');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 


INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);






-- SOLUTIONS

select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;


-- (1) WHAT IS THE TOTAL AMOUNT EACH CUSTOMER SPENT ON ZOMATO

select userid, sum(price) as total_price
from sales s
join product p on p.product_id = s.product_id
group by userid
order by total_price desc;


-- (2) HOW MANY DAYS EACH CUTOMER VISITED ZOMATO

select userid, count(created_date) as no_of_days
from sales
group by userid
order by userid;


-- (3) WHAT WAS THE FIRST PRODUCT PURCHASED BY EACH CUSTOMER??

select * from(
select *,
   rank() over(partition by userid order by created_date ) as rn
from sales) as x
where rn=1;

-- (4) WHAT IS THE MOST PURCHASED ITEM ON THE MENU AND HOW MANY TIMES WAS IT PURCHASED BY ALL CUSTOMERS??


select userid, count(created_date)
from sales  
where product_id in (select product_id
   from  (select product_id, count(product_id) as most_ordered
          from sales
          group by product_id
          order by most_ordered desc
          limit 1) as x          
) group by userid;


-- (5) WHICH ITEN WAS THE MOST POPULAR FOR EACH CUSTOMER


select *
from(
select *,
rank() over(partition by userid order by cnt desc) as rnk 
from(
select userid, product_id, count(product_id) as cnt
from sales
group by userid, product_id
order by userid asc, cnt desc) as x) as y
where rnk =1;


-- (6) WHICH ITEM WAS PURCHASED FIRST BY THE CUSTOMER AFTER THEY BECAME A MEMBER??


select * from(
select *,
rank() over(partition by userid order by created_date asc) as rnk
from 
( select s.*
from sales s
join goldusers_signup g on g.userid=s.userid
where created_date >= gold_signup_date) as x ) as y 
where rnk =1;

-- (7) WHICH ITEM WAS PURCHASED JUST BEFORE A USER BECOME MEMBER

select * from(
select *,
rank() over(partition by userid order by created_date desc) as rnk
from 
( select s.*
from sales s
join goldusers_signup g on g.userid=s.userid
where created_date <= gold_signup_date) as x ) as y 
where rnk =1;

-- (8) WHAT IS THE TOTAL ORDERS AND AMOUNT SPENT BY EACH MEMBER BEFORE THEY BECAME THE MEMBER??


select userid, sum(count*price) as total_amount
from (
select s.userid,s. product_id, count(p.product_id) as count, price
from sales s
join goldusers_signup g on g.userid=s.userid
join product p on p.product_id = s.product_id
where created_date <= gold_signup_date
group by userid, product_id
order by userid asc) as x

group by userid;

-- (9) IF BUYING EACH PRODUCT GENERATES POINTS FOR eg. 5RS= 2 ZOMQTO POINTS AND EACH PRODUCT HAVE DIFFERENT PURCHASING POINTS
--  FOR eg. P1 5RS=1 ZOMATO POINT FOR P2 10RS= 5 ZOMATO POINTS AND FOR P3 5RS= 1 ZOMATO POINT,
-- CALCULATE POINTS COLLECTED BY EACH CUSTOMERS AND FOR WHICH PRODUCT MOST POINTS HAVE BEEN GIVEN BY NOW

select userid, sum(round(total_spent/per_point_cost)) as Points from (
select userid, product_id,total_spent,
case when product_id=1 then 5
when product_id=2 then 2
when product_id=3 then 5
else 0  end as per_point_cost
from (
select userid, product_id, sum(cnt*price) total_spent
from(
select s.userid, p.product_id, count(created_date) as cnt, p.price
from sales s 
join product p on p.product_id = s.product_id 
group by userid, product_id
order by userid) as x
group by userid, product_id) as y) as z
group by userid;

select product_id, sum(round(total_spent/per_point_cost)) as Points from (
select userid, product_id,total_spent,
case when product_id=1 then 5
when product_id=2 then 2
when product_id=3 then 5
else 0  end as per_point_cost
from (
select userid, product_id, sum(cnt*price) total_spent
from(
select s.userid, p.product_id, count(created_date) as cnt, p.price
from sales s 
join product p on p.product_id = s.product_id 
group by userid, product_id
order by userid) as x
group by userid, product_id) as y) as z
group by product_id;

-- (10) IN THE FIRST YEAR WHEN THE CUSTOMER JOINS THE GOLD PROGRAM (INCLUDING THEIR JOINING DATE) IRRESPECTIVE OF WHAT THE CUSTOMER 
-- HAS PURCHASED, THEY EARN 5 ZOMATO POINTS FOR EVERY 10 RS THE SPEND. WHO EAR MORE 1 OR 3 ADN WHAT IS THE TOAL PI\OINTS EARNED AFTER 1YEAR??

select * from goldusers_signup;

select userid, round(total_price/2) as Points
from(

select s.userid, sum(price) as total_price
from sales s
join goldusers_signup g on g.userid = s.userid
join product p on p.product_id = s.product_id
where s.created_date>= gold_signup_date and s.created_date<= date_add(gold_signup_date, interval 1 year)
group by userid) as x
group by userid;

-- (11) RANK ALL THE TRANSACTION OF THE CUSTOMERS


select *,
dense_rank() over(partition by userid order by price asc) as rn
from (select s.userid, s.created_date, p.price
from sales s
join product p on p.product_id=s.product_id
order by userid) as x;


-- (12) RANK ALL THE TRANSACTIONS FOR EACH MEMBER WHENEVER THEY ARE A ZOMATO GOLD MEMBER FOR EVERY NON GOLD MEMBER TRANSACTION MARKED AS NA
 
select userid,created_date,
  case when gold_signup_date is null then "NA" else rn end as ranking
  from(
select s.userid, s.created_date, gold_signup_date,rank() over(partition by userid order by created_date)as rn
from sales s
left join goldusers_signup g on g.userid = s.userid) as x ;



