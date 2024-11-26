SELECT * FROM public.player_seasons;

-- 
CREATE TYPE season_stats as(

			season Integer,
			pts REAL,
			ast REAL,
			reb REAL,
			weight INTEGER
)

CREATE TYPE scoring_class AS ENUM ('star', 'good', 'average', 'bad')

-- drop type season_stats

CREATE TABLE players(

			player_name TEXT,
			height TEXT,
			college TEXT,
			country TEXT,
			draft_year TEXT,
			draft_number TEXT,
			season_stats season_stats[],
			scoring_class scoring_class,
			years_since_last_Season INTEGER,
			current_season Integer,
			PRIMARY KEY(player_name, current_season)
);

-- drop table players;

select * from players
-- Increamentally building the cumulative table for the players and along the way hoding on to the historical data. This happens
-- to be the most powerful and useful modeling techniques which would helps easily flatten a table and unnest according to our requirements.

/*
Why Cumulative Table Design?

Cost Optimization: In the cloud, unnecessary I/O and compute costs pile up quickly. 
CTD helps us reduce these by storing pre-aggregated, cumulative snapshots of data.

Consistency Across Projects: By embedding this design into our internal DE/DS tool (CLUPA), we ensure consistent implementation across 
teams, reduce the risk of data leakage, and simplify adoption.
*/

INSERT INTO players
WITH yesterday as (

		select * from players
		where current_season = 2000
),

today as (

	select * from player_seasons
	where season = 2001
)
 -- Seed query as in 
select 
			coalesce(t.player_name, y.player_name) as player_name,
			coalesce(t.height, y.height) as height,
			coalesce(t.college, y.college) as college,
			coalesce(t.country, y.country) as country,
			coalesce(t.draft_year, y.draft_year) as draft_year,
			coalesce(t.draft_number, y.draft_number) as draft_number,
			case when y.season_stats is null
				 then array[row(
								t.season,
								t.pts,
								t.ast,
								t.reb,
								t.weight
					)::season_stats] -- casting this to the pre-defined datatype that is struct converting the whole row into array of elements.
			when t.season is not null
				 then y.season_stats || array[row(
													t.season,
													t.pts,
													t.ast,
													t.reb,
													t.weight
												)::season_stats]
			else y.season_stats
			END as season_stats,
			case 
				when t.season is not null then 
					case when t.pts > 20 then 'star'
						 when t.pts > 15 then 'good'
						 when t.pts > 10 then 'average'
						 else 'bad'
					end::scoring_class
					else y.scoring_class
			end as scoring_class,
			
			case when t.season is not null then 0
				else y.years_since_last_season + 1
					end as years_since_last_season,
				
		
			coalesce (t.season, y.current_season + 1) as current_season
			
			
from today t FULL OUTER JOIN yesterday y on t.player_name = y.player_name;


-- Unnest the struct  elements that is to seperate out the elements of an array into columns.
with unnested as(
select player_name,
		unnest(season_stats)::season_stats as season_stats
from players 
where current_season = 2001
and player_name = 'Michael Jordan')

select 
player_name, (season_stats::season_stats).* from unnested

/* This is query doesn't have a group by but it seems like we would normally have a group by. You see we would have used min() and max()
and use group by to for non-aggregate elements in the query which would eventually slow dow the query execution time. 

The query below is insanely fast with the help of cumulative table design approach, with no group bys and shuffuling around.

*/
select 	
		player_name,
		(season_stats[CARDINALITY(season_stats)]::season_stats).pts /
		case 
			when (season_stats[1]::season_stats).pts = 0 
				then 1
			else (season_stats[1]::season_stats).pts
		end as improvement
		
from players
where current_season = 2001
and scoring_class = 'star'
order by 2 desc

select * from players
where player_name = 'Don MacLean'
