USE NHLDataWarehouse;
GO

CREATE OR ALTER VIEW reporting.vw_team_season_summary
AS
WITH TeamGames AS
(
    SELECT g.Season,
           g.HomeTeamKey AS TeamKey,
           g.HomeGoals AS GoalsFor,
           g.AwayGoals AS GoalsAgainst,
           g.HomeShots AS ShotsFor,
           g.AwayShots AS ShotsAgainst,
           CASE WHEN g.HomeGoals > g.AwayGoals THEN 1 ELSE 0 END AS Wins,
           CASE WHEN g.HomeGoals < g.AwayGoals THEN 1 ELSE 0 END AS Losses
    FROM fact.GAME_FACT AS g
    UNION ALL
    SELECT g.Season,
           g.AwayTeamKey,
           g.AwayGoals,
           g.HomeGoals,
           g.AwayShots,
           g.HomeShots,
           CASE WHEN g.AwayGoals > g.HomeGoals THEN 1 ELSE 0 END,
           CASE WHEN g.AwayGoals < g.HomeGoals THEN 1 ELSE 0 END
    FROM fact.GAME_FACT AS g
)
SELECT
    tg.Season AS [Season],
    t.TeamName AS [Team],
    COUNT(*) AS [Games Played],
    SUM(tg.Wins) AS [Wins],
    SUM(tg.Losses) AS [Losses],
    SUM(COALESCE(tg.GoalsFor, 0)) AS [Goals For],
    SUM(COALESCE(tg.GoalsAgainst, 0)) AS [Goals Against],
    SUM(COALESCE(tg.ShotsFor, 0)) AS [Shots For],
    SUM(COALESCE(tg.ShotsAgainst, 0)) AS [Shots Against]
FROM TeamGames AS tg
INNER JOIN dimension.TEAM_DIM AS t
    ON t.TeamKey = tg.TeamKey
GROUP BY tg.Season, t.TeamName;
GO
