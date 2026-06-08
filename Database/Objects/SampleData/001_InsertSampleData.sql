/*
    Loads illustrative NHL sample data through the staging and ETL procedures.
    This script is rerunnable and uses fixed sample batch identifiers.
*/
USE NHLDataWarehouse;
GO

DECLARE @TeamLoadBatchID UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111111';
DECLARE @PlayerLoadBatchID UNIQUEIDENTIFIER = '22222222-2222-2222-2222-222222222222';
DECLARE @GameLoadBatchID UNIQUEIDENTIFIER = '33333333-3333-3333-3333-333333333333';
DECLARE @PlayerGameStatsLoadBatchID UNIQUEIDENTIFIER = '44444444-4444-4444-4444-444444444444';

EXEC Dimension.usp_PopulateDateDimension
    @StartDate = '2024-10-01',
    @EndDate = '2024-10-31';

-- Reset fixed sample load batches so audit output reflects the latest sample run.
IF NOT EXISTS (SELECT 1 FROM Audit.LoadBatch WHERE LoadBatchID = @TeamLoadBatchID)
BEGIN
    INSERT INTO Audit.LoadBatch (LoadBatchID, SourceSystem, Status)
    VALUES (@TeamLoadBatchID, 'Sample Data', 'Started');
END
ELSE
BEGIN
    UPDATE Audit.LoadBatch
    SET LoadStartDate = SYSUTCDATETIME(),
        LoadEndDate = NULL,
        Status = 'Started',
        RowsInserted = NULL,
        RowsUpdated = NULL,
        ErrorMessage = NULL
    WHERE LoadBatchID = @TeamLoadBatchID;
END

IF NOT EXISTS (SELECT 1 FROM Audit.LoadBatch WHERE LoadBatchID = @PlayerLoadBatchID)
BEGIN
    INSERT INTO Audit.LoadBatch (LoadBatchID, SourceSystem, Status)
    VALUES (@PlayerLoadBatchID, 'Sample Data', 'Started');
END
ELSE
BEGIN
    UPDATE Audit.LoadBatch
    SET LoadStartDate = SYSUTCDATETIME(),
        LoadEndDate = NULL,
        Status = 'Started',
        RowsInserted = NULL,
        RowsUpdated = NULL,
        ErrorMessage = NULL
    WHERE LoadBatchID = @PlayerLoadBatchID;
END

IF NOT EXISTS (SELECT 1 FROM Audit.LoadBatch WHERE LoadBatchID = @GameLoadBatchID)
BEGIN
    INSERT INTO Audit.LoadBatch (LoadBatchID, SourceSystem, Status)
    VALUES (@GameLoadBatchID, 'Sample Data', 'Started');
END
ELSE
BEGIN
    UPDATE Audit.LoadBatch
    SET LoadStartDate = SYSUTCDATETIME(),
        LoadEndDate = NULL,
        Status = 'Started',
        RowsInserted = NULL,
        RowsUpdated = NULL,
        ErrorMessage = NULL
    WHERE LoadBatchID = @GameLoadBatchID;
END

IF NOT EXISTS (SELECT 1 FROM Audit.LoadBatch WHERE LoadBatchID = @PlayerGameStatsLoadBatchID)
BEGIN
    INSERT INTO Audit.LoadBatch (LoadBatchID, SourceSystem, Status)
    VALUES (@PlayerGameStatsLoadBatchID, 'Sample Data', 'Started');
END
ELSE
BEGIN
    UPDATE Audit.LoadBatch
    SET LoadStartDate = SYSUTCDATETIME(),
        LoadEndDate = NULL,
        Status = 'Started',
        RowsInserted = NULL,
        RowsUpdated = NULL,
        ErrorMessage = NULL
    WHERE LoadBatchID = @PlayerGameStatsLoadBatchID;
END

-- Stage sample teams.
INSERT INTO Staging.TeamRaw
    (LoadBatchID, RawJson, TeamID, TeamName, TeamAbbreviation, Conference, Division)
SELECT @TeamLoadBatchID, '{"teamId":6,"name":"Boston Bruins"}', 6, 'Boston Bruins', 'BOS', 'Eastern', 'Atlantic'
WHERE NOT EXISTS (SELECT 1 FROM Staging.TeamRaw WHERE LoadBatchID = @TeamLoadBatchID AND TeamID = 6);

INSERT INTO Staging.TeamRaw
    (LoadBatchID, RawJson, TeamID, TeamName, TeamAbbreviation, Conference, Division)
SELECT @TeamLoadBatchID, '{"teamId":10,"name":"Toronto Maple Leafs"}', 10, 'Toronto Maple Leafs', 'TOR', 'Eastern', 'Atlantic'
WHERE NOT EXISTS (SELECT 1 FROM Staging.TeamRaw WHERE LoadBatchID = @TeamLoadBatchID AND TeamID = 10);

INSERT INTO Staging.TeamRaw
    (LoadBatchID, RawJson, TeamID, TeamName, TeamAbbreviation, Conference, Division)
SELECT @TeamLoadBatchID, '{"teamId":3,"name":"New York Rangers"}', 3, 'New York Rangers', 'NYR', 'Eastern', 'Metropolitan'
WHERE NOT EXISTS (SELECT 1 FROM Staging.TeamRaw WHERE LoadBatchID = @TeamLoadBatchID AND TeamID = 3);

INSERT INTO Staging.TeamRaw
    (LoadBatchID, RawJson, TeamID, TeamName, TeamAbbreviation, Conference, Division)
SELECT @TeamLoadBatchID, '{"teamId":14,"name":"Tampa Bay Lightning"}', 14, 'Tampa Bay Lightning', 'TBL', 'Eastern', 'Atlantic'
WHERE NOT EXISTS (SELECT 1 FROM Staging.TeamRaw WHERE LoadBatchID = @TeamLoadBatchID AND TeamID = 14);

EXEC Dimension.usp_LoadDimTeam @LoadBatchID = @TeamLoadBatchID;

-- Stage sample players.
INSERT INTO Staging.PlayerRaw
    (LoadBatchID, RawJson, PlayerID, TeamID, FirstName, LastName, FullName, PositionCode, ShootsCatches, BirthDate)
SELECT @PlayerLoadBatchID, '{"playerId":8478403,"fullName":"David Pastrnak"}', 8478403, 6, 'David', 'Pastrnak', 'David Pastrnak', 'RW', 'R', '1996-05-25'
WHERE NOT EXISTS (SELECT 1 FROM Staging.PlayerRaw WHERE LoadBatchID = @PlayerLoadBatchID AND PlayerID = 8478403);

INSERT INTO Staging.PlayerRaw
    (LoadBatchID, RawJson, PlayerID, TeamID, FirstName, LastName, FullName, PositionCode, ShootsCatches, BirthDate)
SELECT @PlayerLoadBatchID, '{"playerId":8473419,"fullName":"Brad Marchand"}', 8473419, 6, 'Brad', 'Marchand', 'Brad Marchand', 'LW', 'L', '1988-05-11'
WHERE NOT EXISTS (SELECT 1 FROM Staging.PlayerRaw WHERE LoadBatchID = @PlayerLoadBatchID AND PlayerID = 8473419);

INSERT INTO Staging.PlayerRaw
    (LoadBatchID, RawJson, PlayerID, TeamID, FirstName, LastName, FullName, PositionCode, ShootsCatches, BirthDate)
SELECT @PlayerLoadBatchID, '{"playerId":8479318,"fullName":"Auston Matthews"}', 8479318, 10, 'Auston', 'Matthews', 'Auston Matthews', 'C', 'R', '1997-09-17'
WHERE NOT EXISTS (SELECT 1 FROM Staging.PlayerRaw WHERE LoadBatchID = @PlayerLoadBatchID AND PlayerID = 8479318);

INSERT INTO Staging.PlayerRaw
    (LoadBatchID, RawJson, PlayerID, TeamID, FirstName, LastName, FullName, PositionCode, ShootsCatches, BirthDate)
SELECT @PlayerLoadBatchID, '{"playerId":8478483,"fullName":"Mitch Marner"}', 8478483, 10, 'Mitch', 'Marner', 'Mitch Marner', 'RW', 'R', '1997-05-05'
WHERE NOT EXISTS (SELECT 1 FROM Staging.PlayerRaw WHERE LoadBatchID = @PlayerLoadBatchID AND PlayerID = 8478483);

INSERT INTO Staging.PlayerRaw
    (LoadBatchID, RawJson, PlayerID, TeamID, FirstName, LastName, FullName, PositionCode, ShootsCatches, BirthDate)
SELECT @PlayerLoadBatchID, '{"playerId":8478048,"fullName":"Artemi Panarin"}', 8478048, 3, 'Artemi', 'Panarin', 'Artemi Panarin', 'LW', 'R', '1991-10-30'
WHERE NOT EXISTS (SELECT 1 FROM Staging.PlayerRaw WHERE LoadBatchID = @PlayerLoadBatchID AND PlayerID = 8478048);

INSERT INTO Staging.PlayerRaw
    (LoadBatchID, RawJson, PlayerID, TeamID, FirstName, LastName, FullName, PositionCode, ShootsCatches, BirthDate)
SELECT @PlayerLoadBatchID, '{"playerId":8480069,"fullName":"Adam Fox"}', 8480069, 3, 'Adam', 'Fox', 'Adam Fox', 'D', 'R', '1998-02-17'
WHERE NOT EXISTS (SELECT 1 FROM Staging.PlayerRaw WHERE LoadBatchID = @PlayerLoadBatchID AND PlayerID = 8480069);

INSERT INTO Staging.PlayerRaw
    (LoadBatchID, RawJson, PlayerID, TeamID, FirstName, LastName, FullName, PositionCode, ShootsCatches, BirthDate)
SELECT @PlayerLoadBatchID, '{"playerId":8476453,"fullName":"Nikita Kucherov"}', 8476453, 14, 'Nikita', 'Kucherov', 'Nikita Kucherov', 'RW', 'L', '1993-06-17'
WHERE NOT EXISTS (SELECT 1 FROM Staging.PlayerRaw WHERE LoadBatchID = @PlayerLoadBatchID AND PlayerID = 8476453);

INSERT INTO Staging.PlayerRaw
    (LoadBatchID, RawJson, PlayerID, TeamID, FirstName, LastName, FullName, PositionCode, ShootsCatches, BirthDate)
SELECT @PlayerLoadBatchID, '{"playerId":8475167,"fullName":"Victor Hedman"}', 8475167, 14, 'Victor', 'Hedman', 'Victor Hedman', 'D', 'L', '1990-12-18'
WHERE NOT EXISTS (SELECT 1 FROM Staging.PlayerRaw WHERE LoadBatchID = @PlayerLoadBatchID AND PlayerID = 8475167);

EXEC Dimension.usp_LoadDimPlayer @LoadBatchID = @PlayerLoadBatchID;

-- Stage sample games.
INSERT INTO Staging.GameRaw
    (LoadBatchID, RawJson, GameID, GameDate, Season, GameType, HomeTeamID, AwayTeamID, HomeGoals, AwayGoals, HomeShots, AwayShots)
SELECT @GameLoadBatchID, '{"gameId":2024020001}', 2024020001, '2024-10-05', '20242025', 'Regular', 6, 10, 4, 2, 32, 28
WHERE NOT EXISTS (SELECT 1 FROM Staging.GameRaw WHERE LoadBatchID = @GameLoadBatchID AND GameID = 2024020001);

INSERT INTO Staging.GameRaw
    (LoadBatchID, RawJson, GameID, GameDate, Season, GameType, HomeTeamID, AwayTeamID, HomeGoals, AwayGoals, HomeShots, AwayShots)
SELECT @GameLoadBatchID, '{"gameId":2024020002}', 2024020002, '2024-10-08', '20242025', 'Regular', 3, 14, 3, 5, 29, 34
WHERE NOT EXISTS (SELECT 1 FROM Staging.GameRaw WHERE LoadBatchID = @GameLoadBatchID AND GameID = 2024020002);

INSERT INTO Staging.GameRaw
    (LoadBatchID, RawJson, GameID, GameDate, Season, GameType, HomeTeamID, AwayTeamID, HomeGoals, AwayGoals, HomeShots, AwayShots)
SELECT @GameLoadBatchID, '{"gameId":2024020003}', 2024020003, '2024-10-12', '20242025', 'Regular', 10, 3, 2, 3, 31, 27
WHERE NOT EXISTS (SELECT 1 FROM Staging.GameRaw WHERE LoadBatchID = @GameLoadBatchID AND GameID = 2024020003);

EXEC Fact.usp_LoadFactGame @LoadBatchID = @GameLoadBatchID;

-- Stage sample player game statistics.
INSERT INTO Staging.PlayerGameStatsRaw
    (LoadBatchID, RawJson, GameID, PlayerID, TeamID, Goals, Assists, Shots, Hits, Blocks, PenaltyMinutes, TimeOnIceSeconds)
SELECT @PlayerGameStatsLoadBatchID, '{"gameId":2024020001,"playerId":8478403}', 2024020001, 8478403, 6, 2, 1, 6, 1, 0, 0, 1210
WHERE NOT EXISTS (SELECT 1 FROM Staging.PlayerGameStatsRaw WHERE LoadBatchID = @PlayerGameStatsLoadBatchID AND GameID = 2024020001 AND PlayerID = 8478403);

INSERT INTO Staging.PlayerGameStatsRaw
    (LoadBatchID, RawJson, GameID, PlayerID, TeamID, Goals, Assists, Shots, Hits, Blocks, PenaltyMinutes, TimeOnIceSeconds)
SELECT @PlayerGameStatsLoadBatchID, '{"gameId":2024020001,"playerId":8473419}', 2024020001, 8473419, 6, 1, 1, 4, 2, 0, 2, 1165
WHERE NOT EXISTS (SELECT 1 FROM Staging.PlayerGameStatsRaw WHERE LoadBatchID = @PlayerGameStatsLoadBatchID AND GameID = 2024020001 AND PlayerID = 8473419);

INSERT INTO Staging.PlayerGameStatsRaw
    (LoadBatchID, RawJson, GameID, PlayerID, TeamID, Goals, Assists, Shots, Hits, Blocks, PenaltyMinutes, TimeOnIceSeconds)
SELECT @PlayerGameStatsLoadBatchID, '{"gameId":2024020001,"playerId":8479318}', 2024020001, 8479318, 10, 1, 0, 5, 1, 1, 0, 1198
WHERE NOT EXISTS (SELECT 1 FROM Staging.PlayerGameStatsRaw WHERE LoadBatchID = @PlayerGameStatsLoadBatchID AND GameID = 2024020001 AND PlayerID = 8479318);

INSERT INTO Staging.PlayerGameStatsRaw
    (LoadBatchID, RawJson, GameID, PlayerID, TeamID, Goals, Assists, Shots, Hits, Blocks, PenaltyMinutes, TimeOnIceSeconds)
SELECT @PlayerGameStatsLoadBatchID, '{"gameId":2024020001,"playerId":8478483}', 2024020001, 8478483, 10, 0, 1, 3, 0, 1, 0, 1180
WHERE NOT EXISTS (SELECT 1 FROM Staging.PlayerGameStatsRaw WHERE LoadBatchID = @PlayerGameStatsLoadBatchID AND GameID = 2024020001 AND PlayerID = 8478483);

INSERT INTO Staging.PlayerGameStatsRaw
    (LoadBatchID, RawJson, GameID, PlayerID, TeamID, Goals, Assists, Shots, Hits, Blocks, PenaltyMinutes, TimeOnIceSeconds)
SELECT @PlayerGameStatsLoadBatchID, '{"gameId":2024020002,"playerId":8478048}', 2024020002, 8478048, 3, 1, 1, 5, 0, 0, 0, 1225
WHERE NOT EXISTS (SELECT 1 FROM Staging.PlayerGameStatsRaw WHERE LoadBatchID = @PlayerGameStatsLoadBatchID AND GameID = 2024020002 AND PlayerID = 8478048);

INSERT INTO Staging.PlayerGameStatsRaw
    (LoadBatchID, RawJson, GameID, PlayerID, TeamID, Goals, Assists, Shots, Hits, Blocks, PenaltyMinutes, TimeOnIceSeconds)
SELECT @PlayerGameStatsLoadBatchID, '{"gameId":2024020002,"playerId":8480069}', 2024020002, 8480069, 3, 0, 2, 2, 1, 3, 0, 1440
WHERE NOT EXISTS (SELECT 1 FROM Staging.PlayerGameStatsRaw WHERE LoadBatchID = @PlayerGameStatsLoadBatchID AND GameID = 2024020002 AND PlayerID = 8480069);

INSERT INTO Staging.PlayerGameStatsRaw
    (LoadBatchID, RawJson, GameID, PlayerID, TeamID, Goals, Assists, Shots, Hits, Blocks, PenaltyMinutes, TimeOnIceSeconds)
SELECT @PlayerGameStatsLoadBatchID, '{"gameId":2024020002,"playerId":8476453}', 2024020002, 8476453, 14, 2, 2, 7, 0, 0, 0, 1264
WHERE NOT EXISTS (SELECT 1 FROM Staging.PlayerGameStatsRaw WHERE LoadBatchID = @PlayerGameStatsLoadBatchID AND GameID = 2024020002 AND PlayerID = 8476453);

INSERT INTO Staging.PlayerGameStatsRaw
    (LoadBatchID, RawJson, GameID, PlayerID, TeamID, Goals, Assists, Shots, Hits, Blocks, PenaltyMinutes, TimeOnIceSeconds)
SELECT @PlayerGameStatsLoadBatchID, '{"gameId":2024020002,"playerId":8475167}', 2024020002, 8475167, 14, 1, 1, 3, 1, 4, 2, 1512
WHERE NOT EXISTS (SELECT 1 FROM Staging.PlayerGameStatsRaw WHERE LoadBatchID = @PlayerGameStatsLoadBatchID AND GameID = 2024020002 AND PlayerID = 8475167);

INSERT INTO Staging.PlayerGameStatsRaw
    (LoadBatchID, RawJson, GameID, PlayerID, TeamID, Goals, Assists, Shots, Hits, Blocks, PenaltyMinutes, TimeOnIceSeconds)
SELECT @PlayerGameStatsLoadBatchID, '{"gameId":2024020003,"playerId":8479318}', 2024020003, 8479318, 10, 1, 0, 6, 1, 0, 0, 1205
WHERE NOT EXISTS (SELECT 1 FROM Staging.PlayerGameStatsRaw WHERE LoadBatchID = @PlayerGameStatsLoadBatchID AND GameID = 2024020003 AND PlayerID = 8479318);

INSERT INTO Staging.PlayerGameStatsRaw
    (LoadBatchID, RawJson, GameID, PlayerID, TeamID, Goals, Assists, Shots, Hits, Blocks, PenaltyMinutes, TimeOnIceSeconds)
SELECT @PlayerGameStatsLoadBatchID, '{"gameId":2024020003,"playerId":8478483}', 2024020003, 8478483, 10, 0, 2, 4, 0, 1, 0, 1176
WHERE NOT EXISTS (SELECT 1 FROM Staging.PlayerGameStatsRaw WHERE LoadBatchID = @PlayerGameStatsLoadBatchID AND GameID = 2024020003 AND PlayerID = 8478483);

INSERT INTO Staging.PlayerGameStatsRaw
    (LoadBatchID, RawJson, GameID, PlayerID, TeamID, Goals, Assists, Shots, Hits, Blocks, PenaltyMinutes, TimeOnIceSeconds)
SELECT @PlayerGameStatsLoadBatchID, '{"gameId":2024020003,"playerId":8478048}', 2024020003, 8478048, 3, 1, 2, 5, 1, 0, 0, 1248
WHERE NOT EXISTS (SELECT 1 FROM Staging.PlayerGameStatsRaw WHERE LoadBatchID = @PlayerGameStatsLoadBatchID AND GameID = 2024020003 AND PlayerID = 8478048);

INSERT INTO Staging.PlayerGameStatsRaw
    (LoadBatchID, RawJson, GameID, PlayerID, TeamID, Goals, Assists, Shots, Hits, Blocks, PenaltyMinutes, TimeOnIceSeconds)
SELECT @PlayerGameStatsLoadBatchID, '{"gameId":2024020003,"playerId":8480069}', 2024020003, 8480069, 3, 0, 1, 2, 1, 2, 0, 1422
WHERE NOT EXISTS (SELECT 1 FROM Staging.PlayerGameStatsRaw WHERE LoadBatchID = @PlayerGameStatsLoadBatchID AND GameID = 2024020003 AND PlayerID = 8480069);

EXEC Fact.usp_LoadFactPlayerGameStats @LoadBatchID = @PlayerGameStatsLoadBatchID;
GO
