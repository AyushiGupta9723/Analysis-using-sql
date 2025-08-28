use sports

--FETCH ALL DATA
select * from team

select * from matches

select * from league

select * from  country 

--ADDING CONSTRAINT NOTNULL BEFORE CREATING PRIMARY KEY

alter table matches
alter column match_api_id VARCHAR(50) NOT NULL;

alter table league
ALTER COLUMN id VARCHAR(50) NOT NULL;

alter table country
ALTER COLUMN id VARCHAR(50) NOT NULL;

--CREATING PRIMARY KEY

alter table team
add constraint p1 primary key(team_api_id)

alter table matches
add constraint p2 primary key(match_api_id)

alter table league
add constraint p3 primary key(id)

alter table country
add constraint p4 primary key(id)

--making same datatype before creating foreign key

alter table matches
alter column home_team_api_id int;

alter table matches
alter column away_team_api_id int;


--CREATING FOREIGN KEY
 ALTER TABLE LEAGUE 
 ADD FOREIGN KEY (country_id) REFERENCES country(id);

 ALTER TABLE matches
 ADD FOREIGN KEY (country_id) REFERENCES country(id);

 ALTER TABLE matches
 ADD FOREIGN KEY (league_id) REFERENCES league(id);

 ALTER TABLE matches
 ADD FOREIGN KEY (home_team_api_id) REFERENCES team(team_api_id);

 ALTER TABLE matches
 ADD FOREIGN KEY (away_team_api_id) REFERENCES team(team_api_id);



 -- to identify duplicates

 select id,team_fifa_api_id,team_long_name,team_short_name
 from team
 group by  id,team_fifa_api_id,team_long_name,team_short_name
 having count(*) >1;


DELETE FROM team
WHERE team_api_id IN (
    SELECT team_api_id FROM (
        SELECT team_api_id,
               ROW_NUMBER() OVER (PARTITION BY id, team_fifa_api_id, team_long_name, team_short_name ORDER BY team_api_id) AS r_n
        FROM team
    ) AS A
    WHERE r_n > 1
);

--to convert datetime 
SELECT CONVERT(DATETIME, date, 120), date
FROM matches
WHERE ISDATE(date) = 1;  -- Only include valid dates


UPDATE matches
SET date = TRY_CONVERT(DATETIME, date)
WHERE ISDATE(date) = 1;



-- build a view 
-- Create a view to have a count of goals made by home team and away team
-- Let the minimum count of goals be 2

alter table matches
alter column home_team_goal int;

alter table matches
alter column away_team_goal int;

Create view home_count_of_goals
as
SELECT matches.home_team_api_id, 
       team.team_long_name,
       SUM(matches.home_team_goal) AS goal_count
FROM matches
JOIN team ON matches.home_team_api_id = team.team_api_id
GROUP BY matches.home_team_api_id, team.team_long_name;

select * from home_count_of_goals;

Create view away_count_of_goals
as
SELECT matches.away_team_api_id, 
       team.team_long_name,
       SUM(matches.away_team_goal) AS goal_count
FROM matches
JOIN team ON matches.away_team_api_id = team.team_api_id
GROUP BY matches.away_team_api_id, team.team_long_name;

select * from away_count_of_goals;

--Find the team won based on the number of goals they have made on the day of the match

team name, date, id


Select M.match_date,T.team_long_name,T.team_short_name,M.winning_team_api_id AS WINNING_TEAM
from
(SELECT match_api_id,date AS match_date,
    CASE 
        WHEN home_team_goal > away_team_goal THEN home_team_api_id
        WHEN away_team_goal > home_team_goal THEN away_team_api_id
		ELSE NULL
    END AS winning_team_api_id
FROM matches) as M
join team as T
on 
M.winning_team_api_id=T.team_api_id;

 --CHECK FOR TIE
SELECT match_api_id, away_team_goal,home_team_goal FROM matches WHERE away_team_goal=home_team_goal;

--CHEECK ALONG WITH TIE
SELECT CONCAT(' " ',home_team_api_id,' " ',' VS ',' " ',away_team_api_id,' " ') as Matches_between,
    M.match_date,
    COALESCE(T.team_long_name, 'TIE') AS team_long_name,
    COALESCE(T.team_short_name, 'TIE') AS team_short_name,
    CASE 
        WHEN M.winning_team_api_id IS NOT NULL THEN M.winning_team_api_id
        ELSE NULL  -- Indicate a tie
    END AS WINNING_TEAM
FROM (
    SELECT 
        match_api_id,home_team_api_id,away_team_api_id,
        date AS match_date,
        CASE 
            WHEN home_team_goal > away_team_goal THEN home_team_api_id
            WHEN away_team_goal > home_team_goal THEN away_team_api_id
            ELSE NULL  -- Use NULL to indicate a tie in winning_team_api_id
        END AS winning_team_api_id
    FROM matches
) AS M 
LEFT JOIN team AS T
ON M.winning_team_api_id = T.team_api_id;


-- List down the country name and the leagues happend on those countries.

select country.name as country_name,
league.name as league_name
from
league 
join
country
on
country.id=league.country_id;


-- country and league can be joined with id and country_id
-- country,league and match can be combined through country_id,league_id from matches table
-- match and team tables can be joined through team_api_id and home_team/away_team

select 
country.name as country_name,
league.name as league_name,
matches.stage,
matches.date,
matches.match_api_id,
home_team.team_long_name as home_team_long_name,
away_team.team_long_name as away_team_long_name,
matches.home_team_goal,
matches.away_team_goal
from
country
join
league
on
country.id=league.country_id
join
matches
on
matches.country_id=country.id
and
matches.league_id=league.id
join
team as home_team
on
matches.home_team_api_id=home_team.team_api_id
join
team as away_team
on
matches.away_team_api_id=away_team.team_api_id;


use feb_proj;


-- calculate the metrics 
-- average home team goals
-- average away team goals
-- average goal difference
-- average goal sum (sum(home+away)/no.of matches)
-- goal sum (sum(home+away))
-- country,league
-- no.of teams -- join with team table and find the count(team_api_id)

select country.name as country_name,
league.name as league_name,
avg(home_team_goal) as avg_home_goals,
avg(away_team_goal) as avg_away_goals,
avg(home_team_goal-away_team_goal) as avg_goal_diff,
avg(home_team_goal+away_team_goal) as avg_goal_sum,
sum(home_team_goal+away_team_goal) as total_goals
from
country
join
league
on
country.id=league.country_id
join
matches
on
country.id=matches.country_id
group by country.name,league.name
order by total_goals desc;




-- store procedure


-- supply a team_api_id , then get the total goals taken by that team when they played as 
-- home team or away team

CREATE PROCEDURE team_goal_count (@team_api_id1 INT)
AS
BEGIN
    SELECT 
        SUM(CASE WHEN home_team_api_id = @team_api_id1 THEN home_team_goal ELSE 0 END) AS home_team_count,
        SUM(CASE WHEN away_team_api_id = @team_api_id1 THEN away_team_goal ELSE 0 END) AS away_team_count
    FROM 
        matches;
END;


exec team_goal_count @team_api_id1=8342;

-- Identify the league where the highest goal count is taken by a home team and a away team.

select league.name as league_name,league_id,sum(away_team_goal+home_team_goal) as total_goal,sum(away_team_goal) as total_away,sum(home_team_goal) as total_home
from league join matches 
on
league.id=matches.league_id
group by league.name,league_id
order by total_goal desc;

--highest goal taken by any league as a away_team and as a home_team

select name from league group by name;


select league.name as league_name,max(away_team_goal) as high_away_team_goal,max(home_team_goal) as high_home_team_goal
from league join matches 
on
league.id=matches.league_id
group by league.name
order by (max(away_team_goal)+max(home_team_goal));



--high score matches
select match_api_id ,id,(away_team_goal+home_team_goal) as total_score from matches
order by total_score desc;



with big_game as 
(
select league_id,match_api_id,home_team_api_id,away_team_api_id,
home_team_goal+away_team_goal as total_goals
from matches
where home_team_goal+away_team_goal>4)

select 
league.name as league_name,
count(big_game.match_api_id) as High_score_matches_count,
sum(total_goals) as total_no_of_goals
from
big_game
join
league
on
league.id=big_game.league_id
group by league.name;




-- Rank the leagues based on the average total number of goals achieved in every league.

select league.name as league_name,
avg(home_team_goal+away_team_goal) as avg_goal,
rank() over (order by avg(home_team_goal+away_team_goal) desc) as league_rank
from
matches
join
league
on
league.id=matches.league_id
group by league.name;



-- calculate the running total of a particular team "KRC Genk" with the id 9987
-- based on the date column in a unbounded preceding and current row.

select 
matches.date,
team.team_long_name as home_team_name,
home_team_goal,
sum(home_team_goal) over (order by matches.date rows between 1 preceding and current row) as running_total
from
matches
join
team
on
team.team_api_id=matches.home_team_api_id
where 
matches.home_team_api_id=9987;









