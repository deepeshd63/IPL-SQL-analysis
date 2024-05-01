/*1.Create and Import IPL Match, and ipl_ball and create the table name of Matches from Ipl_matches 
and Deliveries from IPl_ball */

create table Matches(id int,city varchar,date date,player_of_match varchar,
venue varchar, neutral_venue int,team1 varchar,team2 varchar,
toss_winner varchar, toss_decision varchar,  winner varchar, result varchar, result_margin int,
eliminator varchar, method varchar,umpire1 varchar,umpire2 varchar);
	copy Matches(id, city, date, player_of_match, venue, neutral_venue, 
				team1, team2, toss_winner, toss_decision, winner, result,
				result_margin, eliminator, method, umpire1, umpire2) from 
				'C:\Program Files\PostgreSQL\Data\IPL_matches.csv' delimiter ',' csv header;

select * from Matches;

create table deliveries(id int,inning int,over int, ball int,
batsman varchar,non_striker varchar,bowler varchar,batsman_runs int, extra_runs int,total_runs int,
is_wicket int,dismissal_kind varchar,player_dismissed varchar,fielder varchar, extras_type varchar,batting_team varchar,bowling_team varchar);
copy deliveries from 'C:\Program Files\PostgreSQL\Data\IPL_Ball.csv' delimiter ',' csv header;

select * from deliveries;

--total matches played in each year.
 
 select extract (year from date) as Years ,count(id) total_matches
 from matches
 group by extract (year from date);
 
 /* Project addition task*/
  /*Get the count of cities that have hosted an IPL match*/
  
 SELECT city, count(city) AS num_cities
FROM Matches
GROUP BY city
ORDER BY num_cities DESC;

/* 2. Create table deliveries_v02 with all the columns of the table ‘deliveries’ and an additional 
column ball_result containing values boundary, dot or other depending on the total_run 
(boundary for >= 4, dot for 0 and other for any other number)*/

CREATE TABLE deliveries_v02 AS
SELECT *,CASE WHEN total_runs >= 4 THEN 'boundary'
           WHEN total_runs = 0 THEN 'dot'
           ELSE 'other' END AS ball_result
           FROM deliveries;

select *from deliveries_v02;

/*Write a query to fetch the total number of boundaries and dot balls from the deliveries_v02 table*/
SELECT 
    SUM(CASE WHEN batsman_runs = 4 OR batsman_runs = 6 THEN 1 ELSE 0 END) AS total_boundaries,
    SUM(CASE WHEN batsman_runs = 0 THEN 1 ELSE 0 END) AS total_dot_balls
FROM 
    deliveries_v02;


/* 3. Write a query to fetch the total number of boundaries scored by 
each team from the deliveries_v02 table and order it in descending order of the number of boundaries scored.*/
SELECT batting_team AS team,
SUM(CASE WHEN batsman_runs = 4 OR batsman_runs = 6 THEN 1 ELSE 0 END) AS total_boundaries
FROM deliveries_v02
GROUP BY batting_team
ORDER BY total_boundaries DESC;

/* 4.Write a query to fetch the total number of dot balls bowled by each
team and order it in descending order of the total number of dot balls bowled.*/

SELECT bowling_team AS team,
SUM(CASE WHEN batsman_runs = 0 THEN 1 ELSE 0 END) AS total_dot_balls
FROM deliveries
GROUP BY bowling_team
ORDER BY total_dot_balls DESC limit 15;

/* 5.Write a query to fetch the total number of 
dismissals by dismissal kinds where dismissal kind is not NA*/

SELECT dismissal_kind,
COUNT(*) AS total_dismissals
FROM deliveries
WHERE dismissal_kind <> 'NA'
GROUP BY dismissal_kind;

/* 6.Write a query to get the top 5 
bowlers who conceded maximum extra runs from the deliveries table*/
SELECT bowler,
SUM(extra_runs) AS total_extra_runs
FROM deliveries
GROUP BY bowler
ORDER BY total_extra_runs DESC
LIMIT 5;

/* 7. Write a query to create a table named deliveries_v03 with all the 
columns of deliveries_v02 table and two additional column (named venue and match_date) 
of venue and date from table matches*/

CREATE TABLE deliveries_v03 AS
SELECT d.*, m.venue,
m.date AS match_date
FROM deliveries_v02 d
JOIN matches m ON d.id = m.id;

select * from deliveries_v03;

/* 8. Write a query to fetch the total runs scored for 
each venue and order it in the descending order of total runs scored.*/

SELECT venue, SUM(total_runs) AS total_runs_scored
FROM matches m
JOIN deliveries b ON m.id = b.id
GROUP BY venue
ORDER BY total_runs_scored DESC;

/* 9. Write a query to fetch the year-wise total runs scored at 
Eden Gardens and order it in the descending order of total runs scored.*/

SELECT EXTRACT(YEAR FROM m.date) AS year,
       SUM(b.total_runs) AS total_runs_scored
FROM matches m
JOIN deliveries b ON m.id = b.id
WHERE m.venue = 'Eden Gardens'
GROUP BY EXTRACT(YEAR FROM m.date)
ORDER BY total_runs_scored DESC;


-- 10. Write a query to fetch the total number of boundaries and dot balls from the deliveries_v02 table.
SELECT 
SUM(CASE WHEN b.batsman_runs = 4 OR b.batsman_runs = 6 THEN 1 ELSE 0 END) AS total_boundaries,
SUM(CASE WHEN b.batsman_runs = 0 THEN 1 ELSE 0 END) AS total_dot_balls
FROM deliveries b
JOIN matches m ON b.id = m.id;


--11. Top 10 bowler name by the played matches and took the wickets

SELECT bowler AS BOWLER_NAME,
COUNT(DISTINCT id) AS MATCH_PLAYED,
SUM(IS_WICKET) AS MOST_WICKETS
FROM deliveries
WHERE over < 20
GROUP BY bowler
HAVING COUNT(over) >= 200
AND count(distinct id) >= 50
order by MOST_WICKETS desc
limit 10;


-- 12. Top 20 Batsmen of Strick rate, Batting average, Boundary(4,6), Balls faced, Runs Scored

SELECT COUNT(DISTINCT id) AS MATCH_PLAYED,
batsman AS BATSMAN,
SUM(batsman_runs) AS RUNS_SCORED,
COUNT(ball) AS BALL_FACED,
ROUND((SUM(batsman_runs) / NULLIF(COUNT(DISTINCT ball), 0)) * 100, 2) AS Strike_Rate,
ROUND(SUM(batsman_runs) / NULLIF(SUM(CASE WHEN is_wicket = '1' THEN 1 ELSE 0 END), 0), 2) AS BATTING_AVG,
SUM(CASE WHEN is_wicket = '1' THEN 1 ELSE 0 END) AS GOT_OUT,
(COUNT(DISTINCT id) - SUM(CASE WHEN is_wicket = '1' THEN 1 ELSE 0 END)) AS NOT_OUT,
SUM(CASE WHEN batsman_runs = 4 THEN 1 ELSE 0 END) AS FOURS,
SUM(CASE WHEN batsman_runs = 6 THEN 1 ELSE 0 END) AS SIXES
FROM  deliveries 
GROUP BY batsman
ORDER BY RUNS_SCORED DESC
LIMIT 20;

-- (15)Highest number of sixes by bastman.
SELECT batsman, COUNT(batsman_runs) as Total_sixes
FROM deliveries
WHERE batsman_runs = 6
GROUP BY batsman
HAVING COUNT(batsman_runs) >= 200
ORDER BY COUNT(batsman_runs) DESC;

-- (16)Highest number of FOURS by bastman.
SELECT batsman,COUNT(batsman_runs) as Total_four
FROM deliveries
WHERE batsman_runs = 4
GROUP BY batsman
HAVING count(batsman_runs) >= 200
ORDER BY  COUNT(batsman_runs) DESC;



--any player with max players of match award as Man of Match.
SELECT player_of_match,count(id) TOTAL_Man_of_Match
 FROM matches
 GROUP BY player_of_match
 HAVING count (player_of_match)> 10
 ORDER BY count(id) DESC;
 
 --Balls taken to hit century Balls taken to hit century
SELECT batsman,count(batsman) total_balls
FROM deliveries
GROUP BY batsman,id
HAVING SUM(batsman_runs) >= 100
ORDER BY count(batsman) desc limit 20;


/* 13. Top 20 Bowlers of economy rate, bowling average
stricke rate(bowling) wickets taken, balles bowled*/

SELECT bowler AS Bowler_Name,
ROUND(SUM(total_runs) / NULLIF(SUM(over) / 6, 0), 2) AS Economy_Rate,
ROUND(SUM(total_runs) / NULLIF(SUM(CASE WHEN is_wicket = '1' THEN 1 ELSE 0 END), 0), 2) AS Bowling_Average,
ROUND((SUM(CASE WHEN is_wicket = '1' THEN 1 ELSE 0 END) / NULLIF(SUM(over) / 6, 0)), 2) AS Strike_Rate_Bowling,
SUM(CASE WHEN is_wicket = '1' THEN 1 ELSE 0 END) AS Wickets_Taken,
COUNT(ball) AS Balls_Bowled
FROM deliveries
GROUP BY bowler
ORDER BY Economy_Rate desc, Bowling_Average desc limit 20;

/*--Matches where wictory is by 10 wiclets
SELECT EXTRACT(YEAR FROM date), team1,team2, winner  FROM matches
WHERE result='wickets' AND result_margin = 10;*//

	
/* 14. Top 20 All-rounders Batting strick rate, bowling economy rate, batting and bowling
averages, wicket taken, run scored*/
SELECT Player_Name, Batting_Strike_Rate, Bowling_Economy_Rate, Batting_Average,
Bowling_Average, Wickets_Taken, Runs_Scored
FROM (SELECT batsman AS Player_Name,
ROUND(SUM(batsman_runs) / NULLIF(SUM(ball), 0) * 100, 2) AS Batting_Strike_Rate,
ROUND(SUM(total_runs) / NULLIF(SUM(over) / 6, 0), 2) AS Bowling_Economy_Rate,
ROUND(SUM(batsman_runs) / NULLIF(COUNT(CASE WHEN is_wicket = '1' THEN 1 END), 0), 2) AS Batting_Average,
ROUND(SUM(total_runs) / NULLIF(SUM(CASE WHEN is_wicket = '1' THEN 1 END), 0), 2) AS Bowling_Average,
SUM(CASE WHEN is_wicket = '1' THEN 1 ELSE 0 END) AS Wickets_Taken,
SUM(batsman_runs) AS Runs_Scored
FROM deliveries
GROUP BY batsman) AS sub
order by batting_strike_rate, runs_scored desc
LIMIT 20;



--which batsman got out as run-out maximun time
select player_dismissed , count(is_wicket) as run_out
from deliveries
where dismissal_kind = 'run out'
group by player_dismissed
having count(player_dismissed) >= 10
order by count(is_wicket) desc;



/* 16. Top 20 highest strike rate*/
SELECT batsman, SUM(batsman_runs) AS runs, COUNT(ball) AS balls,
(CAST(SUM(batsman_runs) AS FLOAT) / COUNT(ball))*100 AS strik_rate
FROM deliveries
WHERE NOT (extras_type = 'wides')
GROUP BY batsman
HAVING COUNT(ball) >= 500
ORDER BY strik_rate desc
LIMIT 20;

/* 17. Top 20 with player good average played at least all IPL seasons*/
SELECT b.batsman, CAST(SUM(b.batsman_runs) AS FLOAT) / COUNT(CASE WHEN b.is_wicket = 1 THEN 1 END) AS average_runs,
SUM(b.is_wicket) AS dismissals,
COUNT(DISTINCT(EXTRACT(YEAR FROM m.date))) AS seasons_played
FROM deliveries AS b INNER JOIN matches AS m
ON b.id = m.id
GROUP BY b.batsman
HAVING COUNT(CASE WHEN b.is_wicket = 1 THEN 1 END) >= 1 AND COUNT(DISTINCT(EXTRACT(YEAR FROM m.date))) > 2
ORDER BY average_runs desc
LIMIT 20;

--18. who has taken maximum catches.
select fielder,count(is_wicket) as catch_taken
from deliveries
where dismissal_kind = 'caught'
group by fielder
having count(fielder) >50
order by catch_taken desc;


--21. All Bowler who bowled in ipl with complete stes on name
SELECT bowler AS BOWLER_NAME,
COUNT(DISTINCT id) AS MATCH_PLAYED,
SUM(is_wicket) AS WICKET_TAKEN,
CASE WHEN SUM(CASE WHEN over > 0 THEN 1 ELSE 0 END) = 0 THEN NULL 
ELSE ROUND(SUM(total_runs) / (SUM(CASE WHEN over > 0 THEN 1 ELSE 0 END) / 6.0), 2) 
END AS ECONOMY_RATE,
ROUND(SUM(total_runs) / NULLIF(SUM(is_wicket), 0), 2) AS BOWLING_AVG,
SUM(total_runs) AS TOTAL_RUNS_GIVEN,
ROUND(SUM(over) / 6.0, 0) AS OVERS_BOWLED,
COUNT(ball) AS BALLS_BOWLED,
COUNT(CASE WHEN extras_type = 'wides' THEN 1 END) AS WIDES,
COUNT(CASE WHEN extras_type = 'noballs' THEN 1 END) AS NO_BALLS,
SUM(CASE WHEN batsman_runs = 4 THEN 1 ELSE 0 END) AS FOURS,
SUM(CASE WHEN batsman_runs = 6 THEN 1 ELSE 0 END) AS SIXES
FROM deliveries
GROUP BY bowler
ORDER BY bowler desc;

/* 22. Total number of Boundries by each team*/

SELECT batting_team AS team,
count(ball_result) AS boundries
FROM deliveries_v02
WHERE ball_result = 'boundary'
GROUP BY team
ORDER BY boundries DESC;

/* 23. Total number of Dot bowled by each team*/
SELECT bowling_team AS team,
count(ball_result) AS Dot_Balls
FROM deliveries_v02
WHERE ball_result = 'dot'
GROUP BY team
ORDER BY Dot_Balls DESC;

/* 24. Total Number of dismissals by dismissal kind is NA*/

SELECT dismissal_kind,
COUNT(dismissal_kind) AS no_of_dismissals
FROM deliveries_v02
WHERE NOT (dismissal_kind = 'NA')
GROUP BY dismissal_kind;

select * from deliveries_v02
	
--25. TOTAL RUNS SCORED BY EACH TEAM 

SELECT BATTING_TEAM AS TEAM, SUM(TOTAL_RUNS) AS RUNS_SCORED
FROM deliveries
GROUP BY TEAM
ORDER BY RUNS_SCORED DESC
LIMIT 15;

--26. TOTAL WICKETS TAKEN BY EACH TEAM

SELECT BOWLING_TEAM AS TEAM, SUM(IS_WICKET) AS WICKET_TAKEN
FROM deliveries
GROUP BY TEAM
ORDER BY WICKET_TAKEN DESC limit 15;

--27. WINNER, RESULT BY RUNS OR WICKET 

SELECT winner AS TEAMS,
SUM(CASE WHEN result = 'runs' THEN 1 ELSE 0 END) AS WON_BY_RUNS,
SUM(CASE WHEN result = 'wickets' THEN 1 ELSE 0 END) AS WON_BY_WICKETS
FROM MATCHES
GROUP BY WINNER
HAVING winner NOT IN ('runs' , 'wickets');

--28. TEAMS TOSS ANALYSIS AND TOSS WIN PERCENTAGE 
SELECT toss_winner AS TEAMS, 
COUNT(DISTINCT ID) AS MATCH_PLYAED,
SUM(CASE WHEN toss_decision = 'bat' THEN 1 ELSE 0 END) + 
SUM(CASE WHEN toss_decision = 'field' THEN 1 ELSE 0 END) AS TOSS_WIN,
SUM(CASE WHEN toss_decision NOT IN ('bat' , 'field') THEN 1 ELSE 0 END) AS TOSS_LOSS,
SUM(CASE WHEN toss_decision = 'bat' THEN 1 ELSE 0 END) AS BAT_FIRST,
SUM(CASE WHEN toss_decision = 'field' THEN 1 ELSE 0 END) AS FIELD_FIRST,
ROUND(SUM(CASE WHEN toss_decision = 'bat' THEN 1 ELSE 0 END) + SUM(CASE WHEN toss_decision = 'field' THEN 1 ELSE 0
END) / COUNT(DISTINCT ID) * 100, 2) AS TOSS_WIN_PERCENTAGE 
FROM MATCHES
GROUP BY toss_winner
ORDER BY TOSS_WIN_PERCENTAGE DESC;

--29. How mant time each teams batsman Got out by dismmissal_kind
select batting_team as Batting_team_Got_by,
sum(case when dismissal_kind = 'caught' then 1 end) as Caught,
sum(case when dismissal_kind = 'caught and bowled'then 1 end) as Caught_and_Bowled,
sum(case when dismissal_kind = 'run out' then 1 end) as Run_out,
sum(case when dismissal_kind = 'bowled' then 1 end) as Bowled,
sum(case when dismissal_kind = 'lbw' then 1 end) as LBW,
sum(case when dismissal_kind = 'stumped' then 1 end) as Stumped,
sum(case when dismissal_kind = 'hit wicket' then 1 end) as Hit_wicket,
sum(case when dismissal_kind = 'retired hurt' then 1 end)as Retird_hurt,
sum(case when dismissal_kind = 'obstructing the field' then 1 end) as Obstractucting_field
from deliveries
group by batting_team
order by Batting_team_Got_by
limit 15;

--30. HOW MANY TIMES EACH BOWLING_TEAM_TOOK_WICKETS_BY DISMISSAL_KIND 

SELECT bowling_team AS Team_taken_wicket_by_bowling,
SUM(CASE WHEN dismissal_kind = 'caught' THEN 1 END) AS CAUGHT,
SUM(CASE WHEN dismissal_kind = 'caught and bowled' THEN 1 END) AS CAUGHT_AND_BOWLED,
SUM(CASE WHEN dismissal_kind = 'run out' THEN 1 END) AS RUN_OUT,
SUM(CASE WHEN dismissal_kind = 'bowled' THEN 1 END) AS BOWLED,
SUM(CASE WHEN dismissal_kind = 'lbw' THEN 1 END) AS LBW,
SUM(CASE WHEN dismissal_kind = 'stumped' THEN 1 END) AS STUMPED
FROM deliveries
GROUP BY bowling_team
ORDER BY Team_taken_wicket_by_bowling DESC
LIMIT 15;

/* 31. Total cities that hosted Matches*/

SELECT COUNT(DISTINCT city) AS cities_hosted FROM matches;

SELECT * FROM deliveries_v02;

-- 32. Total of Played
SELECT COUNT(*)as Total_IPL_Matches
FROM matches; 
	
-- 33. TOURNAMENT ANALYSIS according to deliveries table 
SELECT COUNT(DISTINCT ID) AS TOTAL_MATCHES_PLAYED,
COUNT(DISTINCT batsman) AS TOTAL_BATSMAN,
COUNT(DISTINCT bowler) AS TOTAL_BOWLERS,
ROUND(SUM(BALL) / 6, 0) AS TOTAL_APPROX_OVERS_BOWLED,
SUM(TOTAL_RUNS) AS TOTAL_RUNS_SCORED,
SUM(BALL) AS TOTAL_BOWLS_BOWLED,
SUM(IS_WICKET) AS TOTAL_NUMBER_OF_WICKETS,
SUM(EXTRA_RUNS) AS TOTAL_EXTRA_RUNS
FROM deliveries;

-- 34. Total of Match winn by team

SELECT DISTINCT WINNER AS IPL_TEAMS, COUNT(WINNER) AS MATCHES_WIN
FROM matches
WHERE WINNER NOT IN ('BAT' , 'FIELD', 'NA')
GROUP BY WINNER
ORDER BY MATCHES_WIN DESC;

-- 35. TOTAL NUMBER OF MATCH by the Years and totals boundries with Total Runs and Total wicket

SELECT EXTRACT(YEAR FROM m.date) AS match_year,
COUNT(DISTINCT m.id) AS total_matches_played,
SUM(b.total_runs) AS Total_Runs,
COUNT(CASE WHEN b.is_wicket = '1' THEN 1 END) AS Total_wicket
FROM matches m
JOIN deliveries b ON m.id = b.id
GROUP BY match_year
ORDER BY match_year;








					   






	
	

 
  
 

 
 




