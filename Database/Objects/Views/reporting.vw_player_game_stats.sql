USE NHLDataWarehouse;
GO

CREATE OR ALTER VIEW reporting.vw_player_game_stats
AS
SELECT
    g.GameID AS [Game ID],
    d.FullDate AS [Game Date],
    g.Season AS [Season],
    t.TeamName AS [Team],
    p.FullName AS [Player],
    p.PositionCode AS [Position],
    s.Goals AS [Goals],
    s.Assists AS [Assists],
    s.Points AS [Points],
    s.Shots AS [Shots],
    s.Hits AS [Hits],
    s.Blocks AS [Blocks],
    s.PenaltyMinutes AS [Penalty Minutes],
    s.TimeOnIceSeconds AS [Time On Ice Seconds]
FROM fact.PLAYER_GAME_STATS_FACT AS s
INNER JOIN fact.GAME_FACT AS g
    ON g.GameKey = s.GameKey
INNER JOIN dimension.DATE_DIM AS d
    ON d.DateKey = g.DateKey
INNER JOIN dimension.PLAYER_DIM AS p
    ON p.PlayerKey = s.PlayerKey
INNER JOIN dimension.TEAM_DIM AS t
    ON t.TeamKey = s.TeamKey;
GO
