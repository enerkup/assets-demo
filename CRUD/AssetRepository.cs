using CRUD;
using Dapper;
using Microsoft.Data.SqlClient;
using System.Data;

public class AssetRepository
{
    private readonly string _connectionString;

    public AssetRepository(IConfiguration config)
    {
        _connectionString = config.GetConnectionString("DefaultConnection")!;
    }

    public async Task<PagedResult<Asset>> GetAssetsAsync(AssetQueryParams q)
    {
        using var conn = new SqlConnection(_connectionString);

        var parameters = new DynamicParameters();
        parameters.Add("@Search", q.Search);
        parameters.Add("@Status", q.Status);
        parameters.Add("@Category", q.Category);
        parameters.Add("@PageNumber", q.PageNumber);
        parameters.Add("@PageSize", q.PageSize);

        using var multi = await conn.QueryMultipleAsync(
            "dbo.sp_GetAssets",
            parameters,
            commandType: CommandType.StoredProcedure);

        var items = await multi.ReadAsync<Asset>();
        var total = await multi.ReadSingleAsync<int>();

        return new PagedResult<Asset>
        {
            Items = items,
            PageNumber = q.PageNumber,
            PageSize = q.PageSize,
            TotalCount = total
        };
    }
    public async Task AssignAssetAsync(int assetId, int employeeId)
    {
        using var conn = new SqlConnection(_connectionString);

        var parameters = new DynamicParameters();
        parameters.Add("@AssetId", assetId, DbType.Int32);
        parameters.Add("@EmployeeId", employeeId, DbType.Int32);

        await conn.ExecuteAsync(
            "dbo.sp_AssignAsset",
            parameters,
            commandType: CommandType.StoredProcedure);
    }

}