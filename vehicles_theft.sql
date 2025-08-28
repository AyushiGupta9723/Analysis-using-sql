create database vehicle_theft

use vehicle_theft


-- After creating the Db , create the tables 
-- Locations
--Stolen_vehicles
--make_details

--- Make_details- Make_id, Make_name, Make_type

--- Kindly create the tables with these fields (keep the datatype Varchar(max))


-- Make_details
create table Make_details
(make_id varchar(max),make_name varchar(max),make_type varchar(max))


--- Locations
create table locations
(location_id varchar(max), region varchar(max),country varchar(max),population varchar(max), density varchar(max))

--- Stolen_vehicles

create table stolen_vehicles
(vehicle_id varchar(max),vehicle_type varchar(max), make_id varchar(max), model_year varchar(max), vehicle_desc varchar(max), color varchar(max), 
date_stolen varchar(max), location_id varchar(max))



bulk insert stolen_vehicles 
from 'C:\Users\ayush\Downloads\stolen_vehicles.csv'
with ( fieldterminator=',',
rowterminator='\n',
firstrow=2,
maxerrors=0)

bulk insert make_details 
from 'C:\Users\ayush\Downloads\make_details.csv'
with ( fieldterminator=',',
rowterminator='\n',
firstrow=2,
maxerrors=0)
 
 
bulk insert locations 
from 'C:\Users\ayush\Downloads\locations.csv'
with ( fieldterminator=',',
rowterminator='\n',
firstrow=2,
maxerrors=0)

select * from locations
select * from stolen_vehicles
select * from Make_details


---- lET'S CHECK THE DATATYPE OF ALL TABLES

SELECT COLUMN_NAME, DATA_TYPE FROM
INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='Stolen_vehicles'

SELECT *FROM stolen_vehicles

SELECT COLUMN_NAME, DATA_TYPE FROM
INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='Make_details'

SELECT *FROM Make_details

SELECT COLUMN_NAME, DATA_TYPE FROM
INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME='locations'

SELECT *FROM locations

--- Datatype transformation plan-

--V_id-num
--make_id- num
--model_year=num
--date_stolen-date
-- location_id= num

--make details -make_id -num

--locations 
-- l_id,population,density

--vechicle_id

alter table stolen_vehicles
alter column vehicle_id int

--make_id

alter table stolen_vehicles
alter column make_id int

--location id
alter table stolen_vehicles
alter column location_id int


--model year
alter table stolen_vehicles
alter column model_year int

--date stolen

alter table stolen_vehicles
alter column date_stolen date

alter table stolen_vehicles
alter column date_stolen int
 
select * from stolen_vehicles
where isdate(date_stolen)=1

alter table locations
alter column location_id int



select population from locations
where isnumeric(population)=0

update locations
set population =655
where population like '%655%'

alter table locations
alter column population int

update locations
set density=(REPLACE(REPLACE(density, '"', ''), ',', ''))
 where density IN (select density from locations
where isnumeric(density)=0)



UPDATE locations
SET density = ROUND(CAST(density AS FLOAT), 0)
WHERE TRY_CAST(density AS FLOAT) IS NOT NULL;

select *from Make_details
where ISNUMERIC(make_id)=0

alter table make_details
alter column make_id DECIMAL(10,2)


 
 --- Check the duplicates

select *from make_details

select *, row_number() over(order by make_id) as ranking from make_details



--AVERAGE AGE OF STOLEN VEHICLES
select *from Stolen_vehicles
 

 select DATEDIFF(year,date_stolen,getdate()) as year_of_stolen from  stolen_vehicles

select vehicle_type,avg(datediff(Year,model_year,getdate())) as age_of_veh from Stolen_vehicles
group by vehicle_type
order by age_of_veh desc;


--- I want to find the five oldest vehicles in this database


SELECT top 5 vehicle_type,
	   AVG(DATEDIFF(YEAR, model_year, GETDATE())) AS age_of_veh
FROM Stolen_vehicles
GROUP BY vehicle_type
order by age_of_veh desc


with stolen_veh_avg_age as (
SELECT  vehicle_type,
	   AVG(DATEDIFF(YEAR, model_year, GETDATE())) AS age_of_veh
FROM Stolen_vehicles
group by vehicle_type
)

select max(age_of_veh) from stolen_veh_avg_age

--days of stolean

select * ,datename(weekday,date_stolen) as day_name from Stolen_vehicles



SELECT *,	   DATENAME(WEEKDAY, date_stolen) AS day_name
FROM Stolen_vehicles
where DATENAME(WEEKDAY, date_stolen) not in ('Sunday','Saturday')  /* weekdays vehicles stolen list-3380*/

SELECT *,	   DATENAME(WEEKDAY, date_stolen) AS day_name
FROM Stolen_vehicles
where DATENAME(WEEKDAY, date_stolen) in ('Sunday','Saturday')   /* the weekend vehicles stolen list- 1173*/


select DATENAME(WEEKDAY, date_stolen)AS day_name ,count(DATENAME(WEEKDAY, date_stolen)) as total
from stolen_vehicles
group by DATENAME(WEEKDAY, date_stolen)
order by total ;


--- Top 3 vehicle counts are being stolen on weekdays
select top 3 vehicle_type, count(vehicle_id) as 'Vehicle_count', datename(WEEKDAY, date_stolen) as 'day_name' 
from Stolen_vehicles
where datename(WEEKDAY, date_stolen) not in ('Sunday', 'Saturday')
group by vehicle_type,datename(WEEKDAY, date_stolen)
order by vehicle_count desc

select *from Stolen_vehicles
where vehicle_type='saloon'

select *from make_details
where make_id=512

select location_id ,count(location_id) as 'count' from stolen_vehicles
group by location_id
order by 'count';

---------------------------

SELECT region,
	   COUNT(vehicle_id) AS total_stolen_vehicles,
	   COUNT(vehicle_id) / AVG(population) AS rate
FROM locations
JOIN stolen_vehicles ON locations.location_id = stolen_vehicles.location_id
GROUP BY region;



--------------------

select *from Stolen_vehicles
select *from locations

select l.region , count(sv.vehicle_id) as 'Total_Stolen_count' , cast(count(sv.vehicle_id) as float)/l.population *100 as 'Stolen_veh_rates'
from stolen_vehicles Sv
join locations L
on sv.location_id=l.location_id
group by l.region,l.population
order by stolen_veh_rates desc


---------------

with Stolen_veh_profile As (select sv.vehicle_id,vehicle_type,model_year,vehicle_desc,color,date_stolen,l.location_id,
							l.region,l.population,l.density, m.make_id,m.make_name,m.make_type
							from Stolen_vehicles sv
							join locations l
							on sv.location_id=l.location_id
							join make_details m
							on sv.make_id=m.make_id)
select region,count(vehicle_id) as 'Stl_veh_count',
				count(distinct make_name) as 'makers'
				,count(distinct color) as 'dis_color'
				, count(distinct model_year) as 'un_model_year',
				avg(cast(population as float)) as 'Scaled population',
				avg(cast(density as float)) as 'Scaled_density'
from Stolen_veh_profile
group by region
order by region desc



------------
with ranked_vehicles as( Select datename(weekday,date_stolen) as 'Day_name'
						,count(vehicle_id) as 'veh_count',
						row_number() over ( order by count(vehicle_id) Desc) as 'Toprank',
						row_number() over ( order by count(vehicle_id) ) as 'Bottomrank'
						from Stolen_vehicles
						Where date_stolen is not null /* I am excluding if any null values*/
						group by Datename(weekday,date_stolen))
Select day_name,veh_count, 
							Case when Toprank<=3 Then 'Top' +cast(Toprank as varchar(5))
							when Bottomrank<=3 Then 'Bottom' +cast(Bottomrank as varchar(5))
							Else 'NA' End as Ranking
							from ranked_vehicles
							order by 
							Case When Toprank<=3 Then Toprank 
							When Bottomrank <=3 Then 1000+ Bottomrank 
							Else 500
							End ;

