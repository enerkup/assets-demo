namespace loginAPI
{
    public class User
    {
        public Guid UserId { get; set; }
        public int UserTypeId { get; set; }
        public string Username { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string NormalizedEmail { get; set; } = string.Empty;
        public string PasswordHash { get; set; } = string.Empty;  // BCrypt string
        public bool IsActive { get; set; }
    }
}