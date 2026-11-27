create database churnradardb;
use churnradardb;

-- 1) creating the structure (DDL)
-- 1. creating primary customer table
create table customer (
    customerid varchar(50) primary key,
    gender varchar(10),
    senior_citizen int,
    partner varchar(5)
);

-- 2. creating dependents table
create table dependents (
    customerid varchar(50) primary key,
    dependents_yn varchar(5),
    foreign key (customerid) references customer(customerid) on delete cascade
);

-- 3.creating services table
create table services (
    customerid varchar(50) primary key,
    phoneservices varchar(15),
    multiplelines varchar(25),
    internetservice varchar(25),
    onlinesecurity varchar(25),
    onlinebackup varchar(25),
    deviceprotection varchar(25),
    techsupport varchar(25),
    streamingtv varchar(25),
    streamingmovies varchar(25),
    foreign key (customerid) references customer(customerid) on delete cascade
);

-- 4. creating billing & churn table
create table billing (
    customerid varchar(50) primary key,
    tenure int,
    contract varchar(25),
    paperlessbilling varchar(5),
    paymentmethod varchar(50),
    monthlycharges decimal(10,2),
    totalcharges decimal(10,2),
    churn varchar(5),
    foreign key (customerid) references customer(customerid) on delete cascade
);


-- 2) inserting the data into tables (DML)
-- 1. fill customer table
insert into customer (customerid, gender, senior_citizen, partner)
select 
    customerid, 
    gender, 
    case when seniorcitizen in ('Yes', '1') then 1 else 0 end, 
    partner 
from Telco_Customer_Churn_Preprocessed;

-- 2. fill dependents table
insert into dependents (customerid, dependents_yn)
select customerid, dependents 
from Telco_Customer_Churn_Preprocessed;

-- 3. fill services table
insert into services (customerid, phoneservices, multiplelines, internetservice, onlinesecurity, onlinebackup, deviceprotection, techsupport, streamingtv, streamingmovies)
select customerid, phoneservice, multiplelines, internetservice, onlinesecurity, onlinebackup, deviceprotection, techsupport, streamingtv, streamingmovies 
from Telco_Customer_Churn_Preprocessed;

-- 4. fill billing table
insert into billing (customerid, tenure, contract, paperlessbilling, paymentmethod, monthlycharges, totalcharges, churn)
select customerid, tenure, contract, paperlessbilling, paymentmethod, monthlycharges, totalcharges, churn 
from Telco_Customer_Churn_Preprocessed;


-- 3) data retrieval & analytics (DQL)
-- 1. verify row counts across all tables
select 'customer' as table_name, count(*) as total_rows from customer
union all
select 'dependents', count(*) from dependents
union all
select 'services', count(*) from services
union all
select 'billing', count(*) from billing;

-- 2. churn rate & average monthly revenue by contract type
select 
    b.contract,
    count(c.customerid) as total_customers,
    round(avg(b.monthlycharges), 2) as avg_monthly_charge,
    sum(case when b.churn = 'Yes' then 1 else 0 end) as churned_customers,
    round(sum(case when b.churn = 'Yes' then 1.0 else 0 end) * 100 / count(c.customerid), 2) as churn_rate_pct
from customer c
join billing b on c.customerid = b.customerid
group by b.contract
order by churn_rate_pct desc;

-- 3. churn distribution by internet service type
select 
    s.internetservice,
    count(c.customerid) as total_customers,
    sum(case when b.churn = 'Yes' then 1 else 0 end) as churned_customers,
    round(sum(case when b.churn = 'Yes' then 1.0 else 0 end) * 100 / count(c.customerid), 2) as churn_rate_pct
from customer c
join services s on c.customerid = s.customerid
join billing b on c.customerid = b.customerid
group by s.internetservice
order by churn_rate_pct desc;

-- 4. high-risk segment: new fiber optic customers (< 12 months) paying > $80/month
select top 20
    c.customerid,
    c.gender,
    d.dependents_yn,
    b.tenure,
    s.internetservice,
    b.monthlycharges,
    b.churn
from customer c
join dependents d on c.customerid = d.customerid
join services s on c.customerid = s.customerid
join billing b on c.customerid = b.customerid
where s.internetservice = 'Fiber optic'
  and b.monthlycharges > 80.00
  and b.tenure < 12
order by b.monthlycharges desc;
go
-- 4) views & stored procedures (modular code & reusability)
-- 1. view: complete customer churn profile (joins all 4 tables for bi/reporting)
create view vw_customer_churn_summary as
select 
    c.customerid,
    c.gender,
    c.senior_citizen,
    c.partner,
    d.dependents_yn,
    s.phoneservices,
    s.multiplelines,
    s.internetservice,
    s.onlinesecurity,
    s.onlinebackup,
    s.deviceprotection,
    s.techsupport,
    s.streamingtv,
    s.streamingmovies,
    b.tenure,
    b.contract,
    b.paperlessbilling,
    b.paymentmethod,
    b.monthlycharges,
    b.totalcharges,
    b.churn
from customer c
join dependents d on c.customerid = d.customerid
join services s on c.customerid = s.customerid
join billing b on c.customerid = b.customerid;
go

-- 2. view: high-risk active customers (still subscribed, but match top churn drivers)
create view vw_high_risk_active_customers as
select 
    customerid,
    tenure,
    contract,
    internetservice,
    techsupport,
    paymentmethod,
    monthlycharges
from vw_customer_churn_summary
where churn = 'No'
  and contract = 'Month-to-month'
  and monthlycharges > 70.00;
go

-- 3. stored procedure: get churn KPIs for any contract type
create procedure sp_get_churn_by_contract
    @contract_type varchar(25)
as
begin
    select 
        contract,
        count(*) as total_customers,
        round(avg(monthlycharges), 2) as avg_monthly_bill,
        sum(case when churn = 'Yes' then 1 else 0 end) as churned_count,
        round(sum(case when churn = 'Yes' then 1.0 else 0 end) * 100.0 / count(*), 2) as churn_rate_pct
    from vw_customer_churn_summary
    where contract = @contract_type
    group by contract;
end;
go

-- 4. stored procedure: log or update a customer's churn status
create procedure sp_update_customer_churn
    @customerid varchar(50),
    @new_churn_status varchar(5)
as
begin
    update billing
    set churn = @new_churn_status
    where customerid = @customerid;
end;
go

-- test queries to verify views & procedures
select top 10 * from vw_customer_churn_summary;
select top 10 * from vw_high_risk_active_customers;
exec sp_get_churn_by_contract @contract_type = 'Month-to-month';
