USE NHLDataWarehouse;
GO

CREATE OR ALTER VIEW Reporting.vwTeamGameResults
AS
SELECT
    g.GameID AS [Game ID],
    d.FullDate AS [Game Date],
    g.Season AS [Season],
    g.GameType AS [Game Type],
    home.TeamName AS [Home Team],
    away.TeamName AS [Away Team],
    g.HomeGoals AS [Home Goals],
    g.AwayGoals AS [Away Goals],
    g.HomeShots AS [Home Shots],
    g.AwayShots AS [Away Shots],
    CASE
        WHEN g.HomeGoals > g.AwayGoals THEN home.TeamName
        WHEN g.AwayGoals > g.HomeGoals THEN away.TeamName
        ELSE 'Tie'
    END AS [Winning Team]
FROM Fact.Game AS g
INNER JOIN Dimension.[Date] AS d
    ON d.DateKey = g.DateKey
INNER JOIN Dimension.Team AS home
    ON home.TeamKey = g.HomeTeamKey
INNER JOIN Dimension.Team AS away
    ON away.TeamKey = g.AwayTeamKey;
GO
