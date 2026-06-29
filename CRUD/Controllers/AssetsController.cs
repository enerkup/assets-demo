using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authorization;

namespace CRUD.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class AssetsController : ControllerBase
    {
        private readonly AppDbContext _context;
        private readonly AssetRepository _repo;

        public AssetsController(AppDbContext context, AssetRepository repo)
        {
            _context = context;
            _repo = repo;
        }

        // Only admin (UserTypeId == 1)
        [HttpGet]
        //[Authorize(Policy = "AdminOnly")]
        public async Task<ActionResult<PagedResult<Asset>>> GetAssets([FromQuery] AssetQueryParams query)
        {
            if (query.PageNumber < 1) query.PageNumber = 1;
            if (query.PageSize < 1 || query.PageSize > 100) query.PageSize = 20;

            var result = await _repo.GetAssetsAsync(query);
            return Ok(result);
        }

        // POST /assets/assignment — only operator (UserTypeId == 2)
        [HttpPost("assignment")]
        //[Authorize(Policy = "OperatorOnly")]
        public async Task<IActionResult> AssignAsset([FromBody] AssignmentRequest req)
        {
            if (req == null || req.AssetId <= 0 || req.EmployeeId <= 0)
                return BadRequest("AssetId and EmployeeId are required.");

            await _repo.AssignAssetAsync(req.AssetId, req.EmployeeId);
            return NoContent();
        }
    }
}
