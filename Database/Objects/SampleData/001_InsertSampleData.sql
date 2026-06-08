USE NHLDataWarehouse;
GO

EXEC Dimension.usp_PopulateDateDimension @StartDate = '2024-10-01', @EndDate = '2024-10-31';
GO

IF NOT EXISTS (SELECT 1 FROM Dimension.Team WHERE TeamID = 1)
BEGIN
    INSERT INTO Dimension.Team (TeamID, TeamName, TeamAbbreviation, Conference, Division)
    VALUES
        (1, 'Boston Bruins', 'BOS', 'Eastern', 'Atlantic'),
        (2, 'Toronto Maple Leafs', 'TOR', 'Eastern', 'Atlantic');
END
GO

IF NOT EXISTS (SELECT 1 FROM Dimension.Player WHERE PlayerID = 8478403)
BEGIN
    INSERT INTO Dimension.Player (PlayerID, TeamKey, FirstName, LastName, FullName, PositionCode, ShootsCatches, BirthDate)
    SELECT 8478403, TeamKey, 'David', 'Pastrnak', 'David Pastrnak', 'RW', 'R', '1996-05-25'
    FROM Dimension.Team
    WHERE TeamID = 1;

    INSERT INTO Dimension.Player (PlayerID, TeamKey, FirstName, LastName, FullName, PositionCode, ShootsCatches, BirthDate)
    SELECT 8478483, TeamKey, 'Mitch', 'Marner', 'Mitch Marner', 'RW', 'R', '1997-05-05'
    FROM Dimension.Team
    WHERE TeamID = 2;
END
GO

IF NOT EXISTS (SELECT 1 FROM Fact.Game WHERE GameID = 2024020001)
BEGIN
    INSERT INTO Fact.Game
        (GameID, DateKey, Season, GameType, HomeTeamKey, AwayTeamKey, HomeGoals, AwayGoals, HomeShots, AwayShots)
    SELECT 2024020001,
           20241005,
           '20242025',
           'Regular',
           home.TeamKey,
           away.TeamKey,
           4,
           2,
           32,
           28
    FROM Dimension.Team AS home
    CROSS JOIN Dimension.Team AS away
    WHERE home.TeamID = 1
      AND away.TeamID = 2;
END
GO

IF NOT EXISTS
(
    SELECT 1
    FROM Fact.PlayerGameStats AS s
    INNER JOIN Fact.Game AS g ON g.GameKey = s.GameKey
    INNER JOIN Dimension.Player AS p ON p.PlayerKey = s.PlayerKey
    WHERE g.GameID = 2024020001
      AND p.PlayerID = 8478403
)
BEGIN
    INSERT INTO Fact.PlayerGameStats
        (GameKey, PlayerKey, TeamKey, Goals, Assists, Shots, Hits, Blocks, PenaltyMinutes, TimeOnIceSeconds)
    SELECT g.GameKey, p.PlayerKey, t.TeamKey, 2, 1, 6, 1, 0, 0, 1210
    FROM Fact.Game AS g
    INNER JOIN Dimension.Player AS p ON p.PlayerID = 8478403
    INNER JOIN Dimension.Team AS t ON t.TeamID = 1
    WHERE g.GameID = 2024020001;

    INSERT INTO Fact.PlayerGameStats
        (GameKey, PlayerKey, TeamKey, Goals, Assists, Shots, Hits, Blocks, PenaltyMinutes, TimeOnIceSeconds)
    SELECT g.GameKey, p.PlayerKey, t.TeamKey, 1, 1, 4, 0, 1, 2, 1180
    FROM Fact.Game AS g
    INNER JOIN Dimension.Player AS p ON p.PlayerID = 8478483
    INNER JOIN Dimension.Team AS t ON t.TeamID = 2
    WHERE g.GameID = 2024020001;
END
GO
