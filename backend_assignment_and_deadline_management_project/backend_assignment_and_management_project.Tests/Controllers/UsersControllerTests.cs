using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Threading.Tasks;
using backend_assignment_and_management_project.Application.DTOs;
using Xunit;

namespace backend_assignment_and_management_project.Tests.Controllers
{
    public class UsersControllerTests : IClassFixture<CustomWebApplicationFactory<Program>>
    {
        private readonly HttpClient _client;
        private readonly CustomWebApplicationFactory<Program> _factory;

        public UsersControllerTests(CustomWebApplicationFactory<Program> factory)
        {
            _factory = factory;
            _client = factory.CreateClient();
        }

        private async Task<string> AuthenticateAsUserAsync()
        {
            var email = $"regular_user_{Guid.NewGuid()}@example.com";
            var registerRequest = new RegisterRequest
            {
                Name = "Regular User",
                Email = email,
                Password = "Password123"
            };
            await _client.PostAsJsonAsync("/api/auth/register", registerRequest);

            var loginRequest = new LoginRequest
            {
                Email = email,
                Password = "Password123"
            };
            var loginResponse = await _client.PostAsJsonAsync("/api/auth/login", loginRequest);
            var authResult = await loginResponse.Content.ReadFromJsonAsync<AuthResponse>();
            Assert.NotNull(authResult);
            return authResult.Token;
        }

        private async Task<string> AuthenticateAsAdminAsync()
        {
            // The database is seeded automatically in Program.cs with a System Admin
            var loginRequest = new LoginRequest
            {
                Email = "admin@gmail.com",
                Password = "admin123"
            };
            var loginResponse = await _client.PostAsJsonAsync("/api/auth/login", loginRequest);
            var authResult = await loginResponse.Content.ReadFromJsonAsync<AuthResponse>();
            Assert.NotNull(authResult);
            return authResult.Token;
        }

        [Fact]
        public async Task GetLeaderboard_ShouldSucceed()
        {
            // Arrange
            var token = await AuthenticateAsUserAsync();
            _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

            // Act
            var response = await _client.GetAsync("/api/users/leaderboard?limit=5");

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var leaderboard = await response.Content.ReadFromJsonAsync<List<UserResponse>>();
            Assert.NotNull(leaderboard);
        }

        [Fact]
        public async Task GetAllUsers_AsRegularUser_ShouldReturnForbidden()
        {
            // Arrange: Login as a normal user
            var token = await AuthenticateAsUserAsync();
            _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

            // Act: Normal users are not authorized to call GET /api/users
            var response = await _client.GetAsync("/api/users");

            // Assert: Endpoint has [Authorize(Roles = "Admin")]
            Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        }

        [Fact]
        public async Task GetAllUsers_AsAdmin_ShouldSucceed()
        {
            // Arrange: Login as System Admin
            var token = await AuthenticateAsAdminAsync();
            _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

            // Act: Admin is authorized to fetch all users
            var response = await _client.GetAsync("/api/users");

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var users = await response.Content.ReadFromJsonAsync<List<UserResponse>>();
            Assert.NotNull(users);
            Assert.NotEmpty(users);
        }

        [Fact]
        public async Task UpdateProfile_ShouldModifyNameSuccessfully()
        {
            // Arrange
            var token = await AuthenticateAsUserAsync();
            _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

            var updateRequest = new UpdateProfileRequest
            {
                Name = "Updated Name",
                AvatarUrl = "http://my-avatars.com/avatar1.png"
            };

            // Act
            var response = await _client.PutAsJsonAsync("/api/users/profile", updateRequest);

            // Assert
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var updatedUser = await response.Content.ReadFromJsonAsync<UserResponse>();
            Assert.NotNull(updatedUser);
            Assert.Equal("Updated Name", updatedUser.Name);
            Assert.NotNull(updatedUser.AvatarUrl);
            Assert.StartsWith("http", updatedUser.AvatarUrl);
        }
    }
}
