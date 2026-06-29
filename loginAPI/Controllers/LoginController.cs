using Microsoft.AspNetCore.Mvc;

namespace loginAPI.Controllers
{
    [ApiController]
    [Route("[controller]")]
    public class LoginController : ControllerBase
    {
        private readonly UserRepository _users;
        private readonly GenerateJWT _jwt;

        public LoginController(UserRepository users, GenerateJWT jwt)
        {
            _users = users;
            _jwt = jwt;
        }

        [HttpPost(Name = "login")]
        public async Task<IActionResult> Login(LoginRequest request, CancellationToken ct)
        {
            // Normalize the same way the insert side does.
            var normalized = request.Email.ToUpperInvariant();

            var user = await _users.GetByNormalizedEmailAsync(normalized, ct);

            // Same generic message whether the user is missing or the password is wrong —
            // don't reveal which email addresses exist.
            if (user is null || !user.IsActive)
                return Unauthorized("Invalid email or password.");

            bool validPassword = BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash);

            if (!validPassword)
                return Unauthorized("Invalid email or password.");

            var token = _jwt.Generate(user);
            return Ok(new { message = token });
        }
    }
}