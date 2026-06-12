using System.Data;
using System.Globalization;
using System.Net;
using System.Text.Json;
using Microsoft.Data.SqlClient;

const string source_system = "NHL API";
const string default_teams_endpoint = "https://api.nhle.com/stats/rest/en/team";
const string default_schedule_endpoint_template = "https://api-web.nhle.com/v1/schedule/{game_date}";
const string default_roster_endpoint_template = "https://api-web.nhle.com/v1/roster/{team_abbrev}/current";
const string default_boxscore_endpoint_template = "https://api-web.nhle.com/v1/gamecenter/{game_id}/boxscore";

var command_name = args.Length > 0 && !args[0].StartsWith("--", StringComparison.Ordinal)
    ? args[0].ToLowerInvariant()
    : "all";
var option_args = command_name == "all" && args.Length > 0 && args[0].StartsWith("--", StringComparison.Ordinal)
    ? args
    : args.Skip(1).ToArray();
var options = CliOptions.Parse(option_args);

try
{
    var result = command_name switch
    {
        "all" => await RunAllAsync(options),
        "teams" => await TeamLoader.RunAsync(options),
        "players" => await PlayerLoader.RunAsync(options),
        "games" => await GameLoader.RunAsync(options),
        "player-stats" => await PlayerGameStatsLoader.RunAsync(options),
        "replay-procedures" => await ProcedureReplay.RunAsync(),
        _ => Usage($"Unknown command: {command_name}")
    };

    return result;
}
catch (Exception error)
{
    Console.Error.WriteLine($"C# ETL failed: {error.Message}");
    return 1;
}

static async Task<int> RunAllAsync(CliOptions options)
{
    var steps = new List<(string Name, Func<CliOptions, Task<int>> Execute)>
    {
        ("Team dimension ETL", TeamLoader.RunAsync),
        ("Player dimension ETL", PlayerLoader.RunAsync),
        ("Game fact ETL", GameLoader.RunAsync),
        ("Player game stats fact ETL", PlayerGameStatsLoader.RunAsync)
    };

    var step_number = 1;
    foreach (var step in steps)
    {
        Console.WriteLine($"[{step_number}] Starting {step.Name}");
        var result = await step.Execute(options);
        if (result != 0)
        {
            Console.WriteLine($"[{step_number}] {step.Name} failed with exit code {result}");
            return result;
        }

        Console.WriteLine($"[{step_number}] Completed {step.Name}");
        step_number++;
    }

    if (options.IncludeLoadProcedures)
    {
        Console.WriteLine($"[{step_number}] Starting stored procedure load replay");
        var result = await ProcedureReplay.RunAsync();
        if (result != 0)
        {
            Console.WriteLine($"[{step_number}] Stored procedure load replay failed with exit code {result}");
            return result;
        }
    }

    Console.WriteLine("All requested NHL data warehouse C# ETL processes completed.");
    return 0;
}

static int Usage(string? error = null)
{
    if (!string.IsNullOrWhiteSpace(error))
        Console.Error.WriteLine(error);

    Console.WriteLine("""
Usage:
  dotnet run -- all [options]
  dotnet run -- teams [options]
  dotnet run -- players [options]
  dotnet run -- games [options]
  dotnet run -- player-stats [options]
  dotnet run -- replay-procedures

Options:
  --team-abbrevs TOR,BOS
  --start-date 2024-10-04
  --end-date 2024-10-10
  --stats-start-date 2024-10-04
  --stats-end-date 2024-10-10
  --game-ids 2024020001,2024020002
  --include-load-procedures
""");
    return 1;
}

sealed class CliOptions
{
    private readonly Dictionary<string, string> values;
    private readonly HashSet<string> flags;

    private CliOptions(Dictionary<string, string> values, HashSet<string> flags)
    {
        this.values = values;
        this.flags = flags;
    }

    public string TeamsEndpoint => Get("teams-endpoint", "NHL_TEAMS_ENDPOINT", default_teams_endpoint);
    public string RosterEndpointTemplate => Get("roster-endpoint-template", "NHL_ROSTER_ENDPOINT_TEMPLATE", default_roster_endpoint_template);
    public string ScheduleEndpointTemplate => Get("schedule-endpoint-template", "NHL_SCHEDULE_ENDPOINT_TEMPLATE", default_schedule_endpoint_template);
    public string BoxscoreEndpointTemplate => Get("boxscore-endpoint-template", "NHL_BOXSCORE_ENDPOINT_TEMPLATE", default_boxscore_endpoint_template);
    public string? TeamAbbrevs => GetOptional("team-abbrevs", "NHL_TEAM_ABBREVS");
    public DateOnly StartDate => ParseDate(Get("start-date", "NHL_START_DATE", DefaultSeasonStart().ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)));
    public DateOnly EndDate => ParseDate(Get("end-date", "NHL_END_DATE", DateOnly.FromDateTime(DateTime.Today).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture)));
    public DateOnly StatsStartDate => ParseDate(Get("stats-start-date", "NHL_STATS_START_DATE", Get("start-date", "NHL_START_DATE", DateOnly.FromDateTime(DateTime.Today.AddDays(-7)).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture))));
    public DateOnly StatsEndDate => ParseDate(Get("stats-end-date", "NHL_STATS_END_DATE", Get("end-date", "NHL_END_DATE", DateOnly.FromDateTime(DateTime.Today).ToString("yyyy-MM-dd", CultureInfo.InvariantCulture))));
    public string? GameIds => GetOptional("game-ids", "NHL_GAME_IDS");
    public bool IncludeLoadProcedures => flags.Contains("include-load-procedures");

    public static CliOptions Parse(string[] args)
    {
        var values = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        var flags = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        for (var i = 0; i < args.Length; i++)
        {
            var arg = args[i];
            if (!arg.StartsWith("--", StringComparison.Ordinal))
                continue;

            var key = arg[2..];
            if (key.Equals("include-load-procedures", StringComparison.OrdinalIgnoreCase))
            {
                flags.Add(key);
                continue;
            }

            if (i + 1 >= args.Length)
                throw new ArgumentException($"Option {arg} requires a value.");

            values[key] = args[++i];
        }

        return new CliOptions(values, flags);
    }

    private string Get(string key, string environment_name, string default_value)
    {
        if (values.TryGetValue(key, out var value))
            return value;

        return Environment.GetEnvironmentVariable(environment_name) ?? default_value;
    }

    private string? GetOptional(string key, string environment_name)
    {
        if (values.TryGetValue(key, out var value))
            return value;

        return Environment.GetEnvironmentVariable(environment_name);
    }

    private static DateOnly DefaultSeasonStart()
    {
        var today = DateOnly.FromDateTime(DateTime.Today);
        var season_start_year = today.Month >= 9 ? today.Year : today.Year - 1;
        return new DateOnly(season_start_year, 9, 1);
    }

    private static DateOnly ParseDate(string value) =>
        DateOnly.ParseExact(value, "yyyy-MM-dd", CultureInfo.InvariantCulture);
}

static class Warehouse
{
    private static readonly HashSet<string> staging_tables = new(StringComparer.OrdinalIgnoreCase)
    {
        "staging.team_raw",
        "staging.player_raw",
        "staging.game_raw",
        "staging.player_game_stats_raw"
    };

    public static SqlConnection OpenConnection()
    {
        var connection = new SqlConnection(BuildConnectionString());
        connection.Open();
        return connection;
    }

    public static string BuildConnectionString()
    {
        var connection_string = Environment.GetEnvironmentVariable("NHL_DW_CONNECTION_STRING");
        if (!string.IsNullOrWhiteSpace(connection_string))
            return connection_string;

        var server = Environment.GetEnvironmentVariable("NHL_DW_SQL_SERVER") ?? "localhost";
        var database = Environment.GetEnvironmentVariable("NHL_DW_DATABASE") ?? "NHLDataWarehouse";
        var trusted_connection = Environment.GetEnvironmentVariable("NHL_DW_TRUSTED_CONNECTION") ?? "True";
        var trust_server_certificate = Environment.GetEnvironmentVariable("NHL_DW_TRUST_SERVER_CERTIFICATE") ?? "True";

        return $"Server={server};Database={database};Trusted_Connection={trusted_connection};TrustServerCertificate={trust_server_certificate};";
    }

    public static async Task<Guid> StartLoadBatchAsync(SqlConnection connection, SqlTransaction transaction)
    {
        await using var command = new SqlCommand(
            """
            DECLARE @load_batch_id UNIQUEIDENTIFIER;

            EXEC audit.P_START_LOAD_BATCH
                @source_system = @source_system,
                @load_batch_id = @load_batch_id OUTPUT;

            SELECT @load_batch_id;
            """,
            connection,
            transaction);
        command.Parameters.AddWithValue("@source_system", source_system);
        return (Guid)(await command.ExecuteScalarAsync() ?? throw new InvalidOperationException("No load batch id returned."));
    }

    public static async Task MarkBatchFailedAsync(SqlConnection connection, Guid load_batch_id, string error_message)
    {
        await using var command = new SqlCommand(
            """
            EXEC audit.P_END_LOAD_BATCH
                @Load_batch_id = @load_batch_id,
                @Status = 'Failed',
                @RowsInserted = 0,
                @RowsUpdated = 0,
                @ErrorMessage = @error_message;
            """,
            connection);
        command.Parameters.AddWithValue("@load_batch_id", load_batch_id);
        command.Parameters.AddWithValue("@error_message", error_message.Length > 4000 ? error_message[..4000] : error_message);
        await command.ExecuteNonQueryAsync();
    }

    public static async Task TruncateStagingTableAsync(SqlConnection connection, SqlTransaction transaction, string table_name)
    {
        if (!staging_tables.Contains(table_name))
            throw new ArgumentException($"Unsupported staging table for truncate: {table_name}");

        await using var command = new SqlCommand($"TRUNCATE TABLE {table_name};", connection, transaction);
        await command.ExecuteNonQueryAsync();
    }

    public static async Task<int> CountRowsAsync(SqlConnection connection, string table_name)
    {
        await using var command = new SqlCommand($"SELECT COUNT(*) FROM {table_name};", connection);
        return Convert.ToInt32(await command.ExecuteScalarAsync(), CultureInfo.InvariantCulture);
    }

    public static async Task ExecuteProcedureAsync(SqlConnection connection, string command_text, params SqlParameter[] parameters)
    {
        await using var command = new SqlCommand(command_text, connection);
        command.Parameters.AddRange(parameters);
        await command.ExecuteNonQueryAsync();
    }

    public static async Task<int> ExecuteIntScalarAsync(SqlConnection connection, string command_text)
    {
        await using var command = new SqlCommand(command_text, connection);
        return Convert.ToInt32(await command.ExecuteScalarAsync(), CultureInfo.InvariantCulture);
    }

    public static async Task BulkInsertAsync(SqlConnection connection, SqlTransaction transaction, string table_name, DataTable table)
    {
        if (table.Rows.Count == 0)
            return;

        using var bulk_copy = new SqlBulkCopy(connection, SqlBulkCopyOptions.Default, transaction)
        {
            DestinationTableName = table_name
        };

        foreach (DataColumn column in table.Columns)
            bulk_copy.ColumnMappings.Add(column.ColumnName, column.ColumnName);

        await bulk_copy.WriteToServerAsync(table);
    }
}

static class NhlApi
{
    private static readonly HttpClient client = new()
    {
        Timeout = TimeSpan.FromSeconds(30)
    };

    public static async Task<JsonDocument> FetchJsonAsync(string url)
    {
        using var response = await client.GetAsync(url);
        response.EnsureSuccessStatusCode();
        await using var stream = await response.Content.ReadAsStreamAsync();
        return await JsonDocument.ParseAsync(stream);
    }

    public static string? LocalizedText(JsonElement value)
    {
        if (value.ValueKind == JsonValueKind.Object && value.TryGetProperty("default", out var default_value))
            return default_value.ValueKind == JsonValueKind.Null ? null : default_value.ToString();

        return value.ValueKind == JsonValueKind.Null || value.ValueKind == JsonValueKind.Undefined
            ? null
            : value.ToString();
    }

    public static int? GetInt(JsonElement element, string property_name)
    {
        if (!element.TryGetProperty(property_name, out var value) || value.ValueKind == JsonValueKind.Null)
            return null;

        return value.ValueKind == JsonValueKind.Number
            ? value.GetInt32()
            : int.TryParse(value.ToString(), NumberStyles.Integer, CultureInfo.InvariantCulture, out var parsed) ? parsed : null;
    }

    public static string? GetString(JsonElement element, string property_name)
    {
        if (!element.TryGetProperty(property_name, out var value) || value.ValueKind == JsonValueKind.Null)
            return null;

        return value.ToString();
    }

    public static DateTime? GetDate(JsonElement element, string property_name)
    {
        var value = GetString(element, property_name);
        if (string.IsNullOrWhiteSpace(value))
            return null;

        return DateTime.ParseExact(value[..10], "yyyy-MM-dd", CultureInfo.InvariantCulture);
    }

    public static int? TimeOnIceToSeconds(JsonElement element, string property_name)
    {
        var value = GetString(element, property_name);
        if (string.IsNullOrWhiteSpace(value))
            return null;

        var parts = value.Split(':');
        return parts.Length == 2
            && int.TryParse(parts[0], NumberStyles.Integer, CultureInfo.InvariantCulture, out var minutes)
            && int.TryParse(parts[1], NumberStyles.Integer, CultureInfo.InvariantCulture, out var seconds)
            ? (minutes * 60) + seconds
            : null;
    }

    public static IEnumerable<DateOnly> DateRange(DateOnly start_date, DateOnly end_date)
    {
        for (var current_date = start_date; current_date <= end_date; current_date = current_date.AddDays(1))
            yield return current_date;
    }
}

static class TeamReference
{
    public static async Task<List<(int TeamId, string TeamAbbrev)>> FetchAsync(string teams_endpoint)
    {
        using var payload = await NhlApi.FetchJsonAsync(teams_endpoint);
        if (!payload.RootElement.TryGetProperty("data", out var teams) || teams.ValueKind != JsonValueKind.Array)
            throw new InvalidOperationException("NHL team endpoint response did not include a data list.");

        var references = new List<(int TeamId, string TeamAbbrev)>();
        foreach (var team in teams.EnumerateArray())
        {
            var team_id = NhlApi.GetInt(team, "id");
            var team_abbrev = NhlApi.GetString(team, "triCode") ?? NhlApi.GetString(team, "rawTricode");
            if (team_id is not null && !string.IsNullOrWhiteSpace(team_abbrev))
                references.Add((team_id.Value, team_abbrev));
        }

        return references;
    }
}

static class TeamLoader
{
    public static async Task<int> RunAsync(CliOptions options)
    {
        var teams = await FetchTeamsAsync(options.TeamsEndpoint);
        await using var connection = Warehouse.OpenConnection();

        var count_before = await Warehouse.CountRowsAsync(connection, "dimension.team_dim");
        Guid? load_batch_id = null;

        try
        {
            await using (var transaction = await connection.BeginTransactionAsync())
            {
                load_batch_id = await Warehouse.StartLoadBatchAsync(connection, (SqlTransaction)transaction);
                await Warehouse.TruncateStagingTableAsync(connection, (SqlTransaction)transaction, "staging.team_raw");
                await Warehouse.BulkInsertAsync(connection, (SqlTransaction)transaction, "staging.team_raw", ToDataTable(teams, load_batch_id.Value));
                await transaction.CommitAsync();
            }

            await Warehouse.ExecuteProcedureAsync(connection, "EXEC dimension.P_LOAD_DIM_TEAM @load_batch_id = @load_batch_id;", new SqlParameter("@load_batch_id", load_batch_id.Value));
            var count_after = await Warehouse.CountRowsAsync(connection, "dimension.team_dim");
            var duplicate_count = await Warehouse.ExecuteIntScalarAsync(connection, "SELECT COUNT(*) FROM (SELECT team_id FROM dimension.team_dim GROUP BY team_id HAVING COUNT(*) > 1) d;");

            Console.WriteLine($"Load batch: {load_batch_id}");
            Console.WriteLine($"API teams parsed: {teams.Count}");
            Console.WriteLine($"Team dimension count before: {count_before}");
            Console.WriteLine($"Team dimension count after: {count_after}");
            Console.WriteLine($"Duplicate team check rows: {duplicate_count}");
            return duplicate_count == 0 ? 0 : 1;
        }
        catch (Exception error)
        {
            if (load_batch_id is not null)
                await Warehouse.MarkBatchFailedAsync(connection, load_batch_id.Value, error.Message);
            throw;
        }
    }

    private static async Task<List<TeamRow>> FetchTeamsAsync(string endpoint)
    {
        using var payload = await NhlApi.FetchJsonAsync(endpoint);
        if (!payload.RootElement.TryGetProperty("data", out var teams) || teams.ValueKind != JsonValueKind.Array)
            throw new InvalidOperationException("NHL team endpoint response did not include a data list.");

        var rows = new List<TeamRow>();
        foreach (var team in teams.EnumerateArray())
        {
            var team_id = NhlApi.GetInt(team, "id") ?? throw new InvalidOperationException($"Team record is missing id: {team.GetRawText()}");
            var team_name = NhlApi.GetString(team, "fullName") ?? throw new InvalidOperationException($"Team record is missing fullName: {team.GetRawText()}");

            rows.Add(new TeamRow(
                team.GetRawText(),
                team_id,
                team_name,
                NhlApi.GetString(team, "triCode") ?? NhlApi.GetString(team, "rawTricode"),
                NhlApi.GetString(team, "conferenceName"),
                NhlApi.GetString(team, "divisionName")));
        }

        return rows;
    }

    private static DataTable ToDataTable(IEnumerable<TeamRow> teams, Guid load_batch_id)
    {
        var table = StagingTable.Create("source_system", "load_batch_id", "raw_json", "team_id", "team_name", "team_abbreviation", "conference", "division");
        foreach (var team in teams)
            table.Rows.Add(source_system, load_batch_id, team.RawJson, team.TeamId, team.TeamName, DbValue(team.TeamAbbreviation), DbValue(team.Conference), DbValue(team.Division));
        return table;
    }
}

static class PlayerLoader
{
    public static async Task<int> RunAsync(CliOptions options)
    {
        var players = await FetchPlayersAsync(options);
        await using var connection = Warehouse.OpenConnection();

        var count_before = await Warehouse.CountRowsAsync(connection, "dimension.player_dim");
        Guid? load_batch_id = null;

        try
        {
            await using (var transaction = await connection.BeginTransactionAsync())
            {
                load_batch_id = await Warehouse.StartLoadBatchAsync(connection, (SqlTransaction)transaction);
                await Warehouse.TruncateStagingTableAsync(connection, (SqlTransaction)transaction, "staging.player_raw");
                await Warehouse.BulkInsertAsync(connection, (SqlTransaction)transaction, "staging.player_raw", ToDataTable(players, load_batch_id.Value));
                await transaction.CommitAsync();
            }

            await Warehouse.ExecuteProcedureAsync(connection, "EXEC dimension.P_LOAD_DIM_PLAYER @load_batch_id = @load_batch_id;", new SqlParameter("@load_batch_id", load_batch_id.Value));
            var count_after = await Warehouse.CountRowsAsync(connection, "dimension.player_dim");
            var duplicate_count = await Warehouse.ExecuteIntScalarAsync(connection, "SELECT COUNT(*) FROM (SELECT player_id FROM dimension.player_dim GROUP BY player_id HAVING COUNT(*) > 1) d;");

            Console.WriteLine($"Load batch: {load_batch_id}");
            Console.WriteLine($"API players parsed: {players.Count}");
            Console.WriteLine($"Player dimension count before: {count_before}");
            Console.WriteLine($"Player dimension count after: {count_after}");
            Console.WriteLine($"Duplicate player check rows: {duplicate_count}");
            return duplicate_count == 0 ? 0 : 1;
        }
        catch (Exception error)
        {
            if (load_batch_id is not null)
                await Warehouse.MarkBatchFailedAsync(connection, load_batch_id.Value, error.Message);
            throw;
        }
    }

    private static async Task<List<PlayerRow>> FetchPlayersAsync(CliOptions options)
    {
        var selected_team_abbrevs = ParseCodes(options.TeamAbbrevs);
        var teams = await TeamReference.FetchAsync(options.TeamsEndpoint);
        var processed_team_abbrevs = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
        var players = new List<PlayerRow>();

        foreach (var team in teams)
        {
            var team_abbrev = team.TeamAbbrev.ToUpperInvariant();
            if (!processed_team_abbrevs.Add(team_abbrev))
                continue;
            if (selected_team_abbrevs is not null && !selected_team_abbrevs.Contains(team_abbrev))
                continue;

            var roster_url = options.RosterEndpointTemplate.Replace("{team_abbrev}", team_abbrev, StringComparison.OrdinalIgnoreCase);
            JsonDocument roster;
            try
            {
                roster = await NhlApi.FetchJsonAsync(roster_url);
            }
            catch (HttpRequestException error) when (error.StatusCode == HttpStatusCode.NotFound)
            {
                Console.WriteLine($"Roster not found for {team_abbrev}; skipping team.");
                continue;
            }

            using (roster)
            {
                foreach (var roster_group in new[] { "forwards", "defensemen", "goalies" })
                {
                    if (!roster.RootElement.TryGetProperty(roster_group, out var raw_players) || raw_players.ValueKind != JsonValueKind.Array)
                        continue;

                    foreach (var player in raw_players.EnumerateArray())
                    {
                        var player_id = NhlApi.GetInt(player, "id") ?? throw new InvalidOperationException($"Player record is missing id: {player.GetRawText()}");
                        var first_name = player.TryGetProperty("firstName", out var first_name_value) ? NhlApi.LocalizedText(first_name_value) : null;
                        var last_name = player.TryGetProperty("lastName", out var last_name_value) ? NhlApi.LocalizedText(last_name_value) : null;
                        var full_name = string.Join(" ", new[] { first_name, last_name }.Where(value => !string.IsNullOrWhiteSpace(value)));
                        if (string.IsNullOrWhiteSpace(full_name))
                            throw new InvalidOperationException($"Player record is missing name: {player.GetRawText()}");

                        players.Add(new PlayerRow(
                            player.GetRawText(),
                            player_id,
                            team.TeamId,
                            first_name,
                            last_name,
                            full_name,
                            NhlApi.GetString(player, "positionCode"),
                            NhlApi.GetString(player, "shootsCatches"),
                            NhlApi.GetDate(player, "birthDate")));
                    }
                }
            }
        }

        return players;
    }

    private static DataTable ToDataTable(IEnumerable<PlayerRow> players, Guid load_batch_id)
    {
        var table = StagingTable.Create("source_system", "load_batch_id", "raw_json", "player_id", "team_id", "first_name", "last_name", "full_name", "position_code", "shoots_catches", "birth_date");
        foreach (var player in players)
            table.Rows.Add(source_system, load_batch_id, player.RawJson, player.PlayerId, player.TeamId, DbValue(player.FirstName), DbValue(player.LastName), player.FullName, DbValue(player.PositionCode), DbValue(player.ShootsCatches), DbValue(player.BirthDate));
        return table;
    }
}

static class GameLoader
{
    public static async Task<int> RunAsync(CliOptions options)
    {
        var games = await FetchGamesAsync(options.ScheduleEndpointTemplate, options.StartDate, options.EndDate);
        await using var connection = Warehouse.OpenConnection();

        var count_before = await Warehouse.CountRowsAsync(connection, "fact.game_fact");
        Guid? load_batch_id = null;

        try
        {
            await using (var transaction = await connection.BeginTransactionAsync())
            {
                load_batch_id = await Warehouse.StartLoadBatchAsync(connection, (SqlTransaction)transaction);
                await Warehouse.TruncateStagingTableAsync(connection, (SqlTransaction)transaction, "staging.game_raw");
                await Warehouse.BulkInsertAsync(connection, (SqlTransaction)transaction, "staging.game_raw", ToDataTable(games, load_batch_id.Value));
                await transaction.CommitAsync();
            }

            if (games.Count > 0)
            {
                await Warehouse.ExecuteProcedureAsync(
                    connection,
                    """
                    EXEC dimension.P_POPULATE_DATE_DIMENSION
                        @StartDate = @start_date,
                        @EndDate = @end_date;
                    """,
                    new SqlParameter("@start_date", games.Min(game => game.GameDate).ToDateTime(TimeOnly.MinValue)),
                    new SqlParameter("@end_date", games.Max(game => game.GameDate).ToDateTime(TimeOnly.MinValue)));
            }

            await Warehouse.ExecuteProcedureAsync(connection, "EXEC fact.P_LOAD_FACT_GAME @load_batch_id = @load_batch_id;", new SqlParameter("@load_batch_id", load_batch_id.Value));
            var count_after = await Warehouse.CountRowsAsync(connection, "fact.game_fact");
            var duplicate_count = await Warehouse.ExecuteIntScalarAsync(connection, "SELECT COUNT(*) FROM (SELECT game_id FROM fact.game_fact GROUP BY game_id HAVING COUNT(*) > 1) d;");

            Console.WriteLine($"Load batch: {load_batch_id}");
            Console.WriteLine($"API games parsed: {games.Count}");
            Console.WriteLine($"Game fact count before: {count_before}");
            Console.WriteLine($"Game fact count after: {count_after}");
            Console.WriteLine($"Duplicate game check rows: {duplicate_count}");
            return duplicate_count == 0 ? 0 : 1;
        }
        catch (Exception error)
        {
            if (load_batch_id is not null)
                await Warehouse.MarkBatchFailedAsync(connection, load_batch_id.Value, error.Message);
            throw;
        }
    }

    public static async Task<List<GameRow>> FetchGamesAsync(string schedule_endpoint_template, DateOnly start_date, DateOnly end_date)
    {
        var games_by_id = new Dictionary<int, GameRow>();
        foreach (var schedule_date in NhlApi.DateRange(start_date, end_date))
        {
            var schedule_url = schedule_endpoint_template.Replace("{game_date}", schedule_date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture), StringComparison.OrdinalIgnoreCase);
            using var schedule = await NhlApi.FetchJsonAsync(schedule_url);
            if (!schedule.RootElement.TryGetProperty("gameWeek", out var game_week) || game_week.ValueKind != JsonValueKind.Array)
                continue;

            foreach (var schedule_day in game_week.EnumerateArray())
            {
                var game_date_text = NhlApi.GetString(schedule_day, "date");
                if (game_date_text is null || !schedule_day.TryGetProperty("games", out var raw_games) || raw_games.ValueKind != JsonValueKind.Array)
                    continue;

                var game_date = DateOnly.ParseExact(game_date_text, "yyyy-MM-dd", CultureInfo.InvariantCulture);
                foreach (var raw_game in raw_games.EnumerateArray())
                {
                    var game_id = NhlApi.GetInt(raw_game, "id") ?? throw new InvalidOperationException($"Game record is missing id: {raw_game.GetRawText()}");
                    var home_team = raw_game.TryGetProperty("homeTeam", out var home) ? home : default;
                    var away_team = raw_game.TryGetProperty("awayTeam", out var away) ? away : default;

                    games_by_id[game_id] = new GameRow(
                        raw_game.GetRawText(),
                        game_id,
                        game_date,
                        NhlApi.GetString(raw_game, "season"),
                        NhlApi.GetString(raw_game, "gameType"),
                        home_team.ValueKind == JsonValueKind.Object ? NhlApi.GetInt(home_team, "id") : null,
                        away_team.ValueKind == JsonValueKind.Object ? NhlApi.GetInt(away_team, "id") : null,
                        home_team.ValueKind == JsonValueKind.Object ? NhlApi.GetInt(home_team, "score") : null,
                        away_team.ValueKind == JsonValueKind.Object ? NhlApi.GetInt(away_team, "score") : null,
                        home_team.ValueKind == JsonValueKind.Object ? NhlApi.GetInt(home_team, "sog") : null,
                        away_team.ValueKind == JsonValueKind.Object ? NhlApi.GetInt(away_team, "sog") : null);
                }
            }
        }

        return games_by_id.Values.ToList();
    }

    private static DataTable ToDataTable(IEnumerable<GameRow> games, Guid load_batch_id)
    {
        var table = StagingTable.Create("source_system", "load_batch_id", "raw_json", "game_id", "game_date", "season", "game_type", "home_team_id", "away_team_id", "home_goals", "away_goals", "home_shots", "away_shots");
        foreach (var game in games)
            table.Rows.Add(source_system, load_batch_id, game.RawJson, game.GameId, game.GameDate.ToDateTime(TimeOnly.MinValue), DbValue(game.Season), DbValue(game.GameType), DbValue(game.HomeTeamId), DbValue(game.AwayTeamId), DbValue(game.HomeGoals), DbValue(game.AwayGoals), DbValue(game.HomeShots), DbValue(game.AwayShots));
        return table;
    }
}

static class PlayerGameStatsLoader
{
    public static async Task<int> RunAsync(CliOptions options)
    {
        var game_ids = ParseGameIds(options.GameIds);
        if (game_ids.Count == 0)
            game_ids = await FetchGameIdsAsync(options.ScheduleEndpointTemplate, options.StatsStartDate, options.StatsEndDate);

        var stats_rows = await FetchStatsAsync(options.BoxscoreEndpointTemplate, game_ids);
        await using var connection = Warehouse.OpenConnection();

        var count_before = await Warehouse.CountRowsAsync(connection, "fact.player_game_stats_fact");
        Guid? load_batch_id = null;

        try
        {
            await using (var transaction = await connection.BeginTransactionAsync())
            {
                load_batch_id = await Warehouse.StartLoadBatchAsync(connection, (SqlTransaction)transaction);
                await Warehouse.TruncateStagingTableAsync(connection, (SqlTransaction)transaction, "staging.player_game_stats_raw");
                await Warehouse.BulkInsertAsync(connection, (SqlTransaction)transaction, "staging.player_game_stats_raw", ToDataTable(stats_rows, load_batch_id.Value));
                await transaction.CommitAsync();
            }

            await Warehouse.ExecuteProcedureAsync(connection, "EXEC fact.P_LOAD_FACT_PLAYER_GAME_STATS @load_batch_id = @load_batch_id;", new SqlParameter("@load_batch_id", load_batch_id.Value));
            var count_after = await Warehouse.CountRowsAsync(connection, "fact.player_game_stats_fact");
            var duplicate_count = await Warehouse.ExecuteIntScalarAsync(
                connection,
                """
                SELECT  COUNT(*)
                FROM    (
                            SELECT  game_key, player_key, team_key
                            FROM    fact.player_game_stats_fact
                            GROUP BY game_key, player_key, team_key
                            HAVING  COUNT(*) > 1
                        ) d;
                """);

            Console.WriteLine($"Load batch: {load_batch_id}");
            Console.WriteLine($"Game IDs parsed: {game_ids.Count}");
            Console.WriteLine($"API player game stat rows parsed: {stats_rows.Count}");
            Console.WriteLine($"Player game stats fact count before: {count_before}");
            Console.WriteLine($"Player game stats fact count after: {count_after}");
            Console.WriteLine($"Duplicate player/game/team check rows: {duplicate_count}");
            return duplicate_count == 0 ? 0 : 1;
        }
        catch (Exception error)
        {
            if (load_batch_id is not null)
                await Warehouse.MarkBatchFailedAsync(connection, load_batch_id.Value, error.Message);
            throw;
        }
    }

    private static async Task<List<int>> FetchGameIdsAsync(string schedule_endpoint_template, DateOnly start_date, DateOnly end_date)
    {
        var game_ids = new SortedSet<int>();
        foreach (var schedule_date in NhlApi.DateRange(start_date, end_date))
        {
            var schedule_url = schedule_endpoint_template.Replace("{game_date}", schedule_date.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture), StringComparison.OrdinalIgnoreCase);
            using var schedule = await NhlApi.FetchJsonAsync(schedule_url);
            if (!schedule.RootElement.TryGetProperty("gameWeek", out var game_week) || game_week.ValueKind != JsonValueKind.Array)
                continue;

            foreach (var schedule_day in game_week.EnumerateArray())
            {
                if (!schedule_day.TryGetProperty("games", out var games) || games.ValueKind != JsonValueKind.Array)
                    continue;

                foreach (var game in games.EnumerateArray())
                {
                    var state = NhlApi.GetString(game, "gameState");
                    var game_id = NhlApi.GetInt(game, "id");
                    if (game_id is not null && (state == "FINAL" || state == "OFF"))
                        game_ids.Add(game_id.Value);
                }
            }
        }

        return game_ids.ToList();
    }

    private static async Task<List<PlayerStatsRow>> FetchStatsAsync(string boxscore_endpoint_template, IReadOnlyCollection<int> game_ids)
    {
        var rows = new List<PlayerStatsRow>();
        foreach (var game_id in game_ids)
        {
            var boxscore_url = boxscore_endpoint_template.Replace("{game_id}", game_id.ToString(CultureInfo.InvariantCulture), StringComparison.OrdinalIgnoreCase);
            using var boxscore = await NhlApi.FetchJsonAsync(boxscore_url);
            if (!boxscore.RootElement.TryGetProperty("playerByGameStats", out var player_stats))
                continue;

            foreach (var side in new[] { "awayTeam", "homeTeam" })
            {
                if (!boxscore.RootElement.TryGetProperty(side, out var team) || team.ValueKind != JsonValueKind.Object)
                    continue;

                var team_id = NhlApi.GetInt(team, "id");
                if (team_id is null || !player_stats.TryGetProperty(side, out var team_stats))
                    continue;

                foreach (var roster_group in new[] { "forwards", "defense", "goalies" })
                {
                    if (!team_stats.TryGetProperty(roster_group, out var players) || players.ValueKind != JsonValueKind.Array)
                        continue;

                    foreach (var player in players.EnumerateArray())
                    {
                        var player_id = NhlApi.GetInt(player, "playerId");
                        if (player_id is null)
                            continue;

                        rows.Add(new PlayerStatsRow(
                            player.GetRawText(),
                            game_id,
                            player_id.Value,
                            team_id.Value,
                            NhlApi.GetInt(player, "goals"),
                            NhlApi.GetInt(player, "assists"),
                            NhlApi.GetInt(player, "sog"),
                            NhlApi.GetInt(player, "hits"),
                            NhlApi.GetInt(player, "blockedShots"),
                            NhlApi.GetInt(player, "pim"),
                            NhlApi.TimeOnIceToSeconds(player, "toi")));
                    }
                }
            }
        }

        return rows;
    }

    private static DataTable ToDataTable(IEnumerable<PlayerStatsRow> stats_rows, Guid load_batch_id)
    {
        var table = StagingTable.Create("source_system", "load_batch_id", "raw_json", "game_id", "player_id", "team_id", "goals", "assists", "shots", "hits", "blocks", "penalty_minutes", "time_on_ice_seconds");
        foreach (var stats in stats_rows)
            table.Rows.Add(source_system, load_batch_id, stats.RawJson, stats.GameId, stats.PlayerId, stats.TeamId, DbValue(stats.Goals), DbValue(stats.Assists), DbValue(stats.Shots), DbValue(stats.Hits), DbValue(stats.Blocks), DbValue(stats.PenaltyMinutes), DbValue(stats.TimeOnIceSeconds));
        return table;
    }
}

static class ProcedureReplay
{
    private static readonly Dictionary<string, string> load_batch_tables = new(StringComparer.OrdinalIgnoreCase)
    {
        ["team"] = "staging.team_raw",
        ["player"] = "staging.player_raw",
        ["game"] = "staging.game_raw",
        ["player_game_stats"] = "staging.player_game_stats_raw"
    };

    public static async Task<int> RunAsync()
    {
        await using var connection = Warehouse.OpenConnection();

        var (start_date, end_date) = await GetGameDateRangeAsync(connection);
        Console.WriteLine("Executing dimension.P_POPULATE_DATE_DIMENSION");
        await Warehouse.ExecuteProcedureAsync(
            connection,
            """
            EXEC dimension.P_POPULATE_DATE_DIMENSION
                @StartDate = @start_date,
                @EndDate = @end_date;
            """,
            new SqlParameter("@start_date", start_date),
            new SqlParameter("@end_date", end_date));
        Console.WriteLine($"DATE_DIM range loaded: {start_date:yyyy-MM-dd} through {end_date:yyyy-MM-dd}");

        foreach (var (procedure_name, staging_table_name) in new[]
        {
            ("dimension.P_LOAD_DIM_TEAM", load_batch_tables["team"]),
            ("dimension.P_LOAD_DIM_PLAYER", load_batch_tables["player"]),
            ("fact.P_LOAD_FACT_GAME", load_batch_tables["game"]),
            ("fact.P_LOAD_FACT_PLAYER_GAME_STATS", load_batch_tables["player_game_stats"])
        })
        {
            Console.WriteLine($"Executing {procedure_name}");
            var load_batch_id = await GetLatestLoadBatchIdAsync(connection, staging_table_name);
            await Warehouse.ExecuteProcedureAsync(connection, $"EXEC {procedure_name} @load_batch_id = @load_batch_id;", new SqlParameter("@load_batch_id", load_batch_id));
            Console.WriteLine($"{procedure_name} completed for load batch {load_batch_id}");
        }

        return 0;
    }

    private static async Task<(DateTime StartDate, DateTime EndDate)> GetGameDateRangeAsync(SqlConnection connection)
    {
        await using var command = new SqlCommand(
            """
            SELECT  MIN(game_date) AS start_date,
                    MAX(game_date) AS end_date
            FROM    staging.game_raw
            WHERE   game_date IS NOT NULL;
            """,
            connection);
        await using var reader = await command.ExecuteReaderAsync(CommandBehavior.SingleRow);
        if (!await reader.ReadAsync() || reader.IsDBNull(0) || reader.IsDBNull(1))
            throw new InvalidOperationException("staging.game_raw does not contain game dates for DATE_DIM.");

        return (reader.GetDateTime(0), reader.GetDateTime(1));
    }

    private static async Task<Guid> GetLatestLoadBatchIdAsync(SqlConnection connection, string table_name)
    {
        if (!load_batch_tables.ContainsValue(table_name))
            throw new ArgumentException($"Unsupported staging table: {table_name}");

        await using var command = new SqlCommand(
            $"""
            SELECT  TOP (1)
                    load_batch_id
            FROM    {table_name}
            WHERE   load_batch_id IS NOT NULL
            GROUP BY load_batch_id
            ORDER BY MAX(created_date) DESC;
            """,
            connection);
        return (Guid)(await command.ExecuteScalarAsync() ?? throw new InvalidOperationException($"{table_name} does not contain a load_batch_id."));
    }
}

static class StagingTable
{
    public static DataTable Create(params string[] columns)
    {
        var table = new DataTable();
        foreach (var column in columns)
            table.Columns.Add(column, typeof(object));
        return table;
    }
}

static object DbValue(object? value) => value ?? DBNull.Value;

static HashSet<string>? ParseCodes(string? value)
{
    if (string.IsNullOrWhiteSpace(value))
        return null;

    return value.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
        .Select(item => item.ToUpperInvariant())
        .ToHashSet(StringComparer.OrdinalIgnoreCase);
}

static List<int> ParseGameIds(string? value)
{
    if (string.IsNullOrWhiteSpace(value))
        return new List<int>();

    return value.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
        .Select(item => int.Parse(item, CultureInfo.InvariantCulture))
        .ToList();
}

sealed record TeamRow(string RawJson, int TeamId, string TeamName, string? TeamAbbreviation, string? Conference, string? Division);
sealed record PlayerRow(string RawJson, int PlayerId, int TeamId, string? FirstName, string? LastName, string FullName, string? PositionCode, string? ShootsCatches, DateTime? BirthDate);
sealed record GameRow(string RawJson, int GameId, DateOnly GameDate, string? Season, string? GameType, int? HomeTeamId, int? AwayTeamId, int? HomeGoals, int? AwayGoals, int? HomeShots, int? AwayShots);
sealed record PlayerStatsRow(string RawJson, int GameId, int PlayerId, int TeamId, int? Goals, int? Assists, int? Shots, int? Hits, int? Blocks, int? PenaltyMinutes, int? TimeOnIceSeconds);
