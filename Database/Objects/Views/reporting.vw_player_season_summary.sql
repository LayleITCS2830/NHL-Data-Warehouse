USE NHLDataWarehouse;
GO

CREATE OR ALTER VIEW reporting.V_PLAYER_SEASON_SUMMARY
AS
SELECT  g.season AS [Season],
        t.team_name AS [Team],
        p.full_name AS [Player],
        p.position_code AS [Position],
        COUNT(*) AS [Games Played],
        SUM(s.goals) AS [Goals],
        SUM(s.assists) AS [Assists],
        SUM(s.points) AS [Points],
        SUM(s.shots) AS [Shots],
        SUM(s.hits) AS [Hits],
        SUM(s.blocks) AS [Blocks],
        SUM(s.penalty_minutes) AS [Penalty Minutes],
        SUM(COALESCE(s.time_on_ice_seconds, 0)) AS [Time On Ice Seconds]
FROM    fact.player_game_stats_fact     s
JOIN    fact.game_fact                  g   ON  g.game_key = s.game_key
JOIN    dimension.player_dim            p   ON  p.player_key = s.player_key
JOIN    dimension.team_dim              t   ON  t.team_key = s.team_key
GROUP BY g.season, t.team_name, p.full_name, p.position_code;
GO
