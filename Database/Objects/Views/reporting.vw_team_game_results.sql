USE NHLDataWarehouse;
GO

CREATE OR ALTER VIEW reporting.V_TEAM_GAME_RESULTS
AS
SELECT  g.game_id AS [Game ID],
        d.full_date AS [Game Date],
        g.season AS [Season],
        g.game_type AS [Game Type],
        home.team_name AS [Home Team],
        away.team_name AS [Away Team],
        g.home_goals AS [Home Goals],
        g.away_goals AS [Away Goals],
        g.home_shots AS [Home Shots],
        g.away_shots AS [Away Shots],
        CASE
            WHEN g.home_goals > g.away_goals THEN home.team_name
            WHEN g.away_goals > g.home_goals THEN away.team_name
            ELSE 'Tie'
        END AS [Winning Team]
FROM    fact.game_fact          g
JOIN    dimension.date_dim      d       ON  d.date_key = g.date_key
JOIN    dimension.team_dim      home    ON  home.team_key = g.home_team_key
JOIN    dimension.team_dim      away    ON  away.team_key = g.away_team_key;
GO
