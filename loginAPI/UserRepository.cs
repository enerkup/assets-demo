using loginAPI;
using Microsoft.Data.SqlClient;
using System.Data;

public record CreateUserRequest(
    string Username,
    string Email,
    string FirstName,
    string LastName,
    string Password,
    int UserTypeId
    );

public class UserRepository
{

    private readonly string _connectionString;

    public UserRepository(IConfiguration config)
    {
        _connectionString = config.GetConnectionString("DefaultConnection")!;
    }

    public async Task<Guid> CreateUserAsync(
        CreateUserRequest request,
        string passwordHash,
        CancellationToken ct = default)
    {
        await using var connection = new SqlConnection(_connectionString);
        await using var command = new SqlCommand("dbo.sp_InsertUser", connection)
        {
            CommandType = CommandType.StoredProcedure
        };

        command.Parameters.Add("@Username", SqlDbType.NVarChar, 256).Value = request.Username;
        command.Parameters.Add("@Email", SqlDbType.NVarChar, 256).Value = request.Email;
        command.Parameters.Add("@NormalizedEmail", SqlDbType.NVarChar, 256).Value = request.Email.ToUpperInvariant();
        command.Parameters.Add("@PasswordHash", SqlDbType.NVarChar, 256).Value = passwordHash;
        command.Parameters.Add("@FirstName", SqlDbType.NVarChar, 100).Value = request.FirstName;
        command.Parameters.Add("@LastName", SqlDbType.NVarChar, 100).Value = request.LastName;
        command.Parameters.Add("@UserTypeId", SqlDbType.Int, 1).Value = request.UserTypeId;

        var newIdParam = new SqlParameter("@NewUserId", SqlDbType.UniqueIdentifier)
        {
            Direction = ParameterDirection.Output
        };
        command.Parameters.Add(newIdParam);

        //handle issues to don't expose data 

        try
        {
            await connection.OpenAsync(ct);
            await command.ExecuteNonQueryAsync(ct);
        }
        catch (SqlException ex)
        {
            throw new InvalidOperationException(ex.Message, ex);
        }

        Guid newId = (Guid)newIdParam.Value;
        return newId;
    }


    public async Task<User?> GetByNormalizedEmailAsync(
            string normalizedEmail, CancellationToken ct = default)
    {
        await using var conn = new SqlConnection(_connectionString);
        await using var cmd = new SqlCommand("dbo.sp_GetUser", conn)
        {
            CommandType = CommandType.StoredProcedure
        };
        cmd.Parameters.Add("@NormalizedEmail", SqlDbType.NVarChar, 256).Value = normalizedEmail;

        await conn.OpenAsync(ct);
        await using var reader = await cmd.ExecuteReaderAsync(ct);

        if (!await reader.ReadAsync(ct))
            return null;

        return new User
        {
            UserId = reader.GetGuid(reader.GetOrdinal("UserId")),
            UserTypeId = reader.GetInt32(reader.GetOrdinal("UserTypeId")),
            Username = reader.GetString(reader.GetOrdinal("Username")),
            Email = reader.GetString(reader.GetOrdinal("Email")),
            PasswordHash = reader.GetString(reader.GetOrdinal("PasswordHash")), // string now
            IsActive = reader.GetBoolean(reader.GetOrdinal("IsActive"))
        };
    }

}