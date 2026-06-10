USE NHLDataWarehouse;
GO

CREATE OR ALTER VIEW reporting.V_TEAM_SEASON_SUMMARY
AS
WITH team_games AS
(
    SELECT  g.season,
            g.home_team_key AS team_key,
            g.home_goals AS goals_for,
            g.away_goals AS goals_against,
            g.home_shots AS shots_for,
            g.away_shots AS shots_against,
            CASE WHEN g.home_goals > g.away_goals THEN 1 ELSE 0 END AS wins,
            CASE WHEN g.home_goals < g.away_goals THEN 1 ELSE 0 END AS losses
    FROM    fact.game_fact  g
    UNION ALL
    SELECT  g.season,
            g.away_team_key,
            g.away_goals,
            g.home_goals,
            g.away_shots,
            g.home_shots,
            CASE WHEN g.away_goals > g.home_goals THEN 1 ELSE 0 END,
            CASE WHEN g.away_goals < g.home_goals THEN 1 ELSE 0 END
    FROM    fact.game_fact  g
)
SELECT  tg.season AS [Season],
        t.team_name AS [Team],
        COUNT(*) AS [Games Played],
        SUM(tg.wins) AS [Wins],
        SUM(tg.losses) AS [Losses],
        SUM(COALESCE(tg.goals_for, 0)) AS [Goals For],
        SUM(COALESCE(tg.goals_against, 0)) AS [Goals Against],
        SUM(COALESCE(tg.shots_for, 0)) AS [Shots For],
        SUM(COALESCE(tg.shots_against, 0)) AS [Shots Against]
FROM    team_games          tg
JOIN    dimension.team_dim  t   ON  t.team_key = tg.team_key
GROUP BY tg.season, t.team_name;
GO
