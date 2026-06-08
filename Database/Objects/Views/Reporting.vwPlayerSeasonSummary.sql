USE NHLDataWarehouse;
GO

CREATE OR ALTER VIEW Reporting.vwPlayerSeasonSummary
AS
SELECT
    g.Season AS [Season],
    t.TeamName AS [Team],
    p.FullName AS [Player],
    p.PositionCode AS [Position],
    COUNT(*) AS [Games Played],
    SUM(s.Goals) AS [Goals],
    SUM(s.Assists) AS [Assists],
    SUM(s.Points) AS [Points],
    SUM(s.Shots) AS [Shots],
    SUM(s.Hits) AS [Hits],
    SUM(s.Blocks) AS [Blocks],
    SUM(s.PenaltyMinutes) AS [Penalty Minutes],
    SUM(COALESCE(s.TimeOnIceSeconds, 0)) AS [Time On Ice Seconds]
FROM Fact.PlayerGameStats AS s
INNER JOIN Fact.Game AS g
    ON g.GameKey = s.GameKey
INNER JOIN Dimension.Player AS p
    ON p.PlayerKey = s.PlayerKey
INNER JOIN Dimension.Team AS t
    ON t.TeamKey = s.TeamKey
GROUP BY g.Season, t.TeamName, p.FullName, p.PositionCode;
GO
