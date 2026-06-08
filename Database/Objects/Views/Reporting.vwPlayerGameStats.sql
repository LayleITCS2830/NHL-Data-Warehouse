USE NHLDataWarehouse;
GO

CREATE OR ALTER VIEW Reporting.vwPlayerGameStats
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
FROM Fact.PlayerGameStats AS s
INNER JOIN Fact.Game AS g
    ON g.GameKey = s.GameKey
INNER JOIN Dimension.[Date] AS d
    ON d.DateKey = g.DateKey
INNER JOIN Dimension.Player AS p
    ON p.PlayerKey = s.PlayerKey
INNER JOIN Dimension.Team AS t
    ON t.TeamKey = s.TeamKey;
GO
