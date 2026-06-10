USE NHLDataWarehouse;
GO

CREATE OR ALTER VIEW reporting.V_PLAYER_GAME_STATS
AS
SELECT  g.game_id AS [Game ID],
        d.full_date AS [Game Date],
        g.season AS [Season],
        t.team_name AS [Team],
        p.full_name AS [Player],
        p.position_code AS [Position],
        s.goals AS [Goals],
        s.assists AS [Assists],
        s.points AS [Points],
        s.shots AS [Shots],
        s.hits AS [Hits],
        s.blocks AS [Blocks],
        s.penalty_minutes AS [Penalty Minutes],
        s.time_on_ice_seconds AS [Time On Ice Seconds]
FROM    fact.player_game_stats_fact     s
JOIN    fact.game_fact                  g   ON  g.game_key = s.game_key
JOIN    dimension.date_dim              d   ON  d.date_key = g.date_key
JOIN    dimension.player_dim            p   ON  p.player_key = s.player_key
JOIN    dimension.team_dim              t   ON  t.team_key = s.team_key;
GO
