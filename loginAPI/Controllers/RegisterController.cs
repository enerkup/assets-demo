using Microsoft.AspNetCore.Mvc;

[ApiController]
[Route("[controller]")]
public class RegisterController : ControllerBase
{
    private readonly UserRepository _users;

    public RegisterController(UserRepository users)
    {
        _users = users;
    }

    [HttpPost]
    public async Task<IActionResult> Create(
        [FromBody] CreateUserRequest request,
        CancellationToken ct)
    {

        try
        {
            // Generate the hash here, in app code.
            string passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);
            Guid newId = await _users.CreateUserAsync(request, passwordHash, ct);
            return CreatedAtAction(nameof(Create), new { id = newId }, new { id = newId });
        }

        catch (InvalidOperationException ex)
        {
            return BadRequest(new { error = ex.Message });
        }

    }

}