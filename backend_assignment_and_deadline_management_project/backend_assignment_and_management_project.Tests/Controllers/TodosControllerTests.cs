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
    public class TodosControllerTests : IClassFixture<CustomWebApplicationFactory<Program>>
    {
        private readonly HttpClient _client;
        private readonly CustomWebApplicationFactory<Program> _factory;

        public TodosControllerTests(CustomWebApplicationFactory<Program> factory)
        {
            _factory = factory;
            _client = factory.CreateClient();
        }

        private async Task<string> AuthenticateAsync()
        {
            // Register a new user
            var email = $"todo_user_{Guid.NewGuid()}@example.com";
            var registerRequest = new RegisterRequest
            {
                Name = "Todo User",
                Email = email,
                Password = "Password123"
            };
            await _client.PostAsJsonAsync("/api/auth/register", registerRequest);

            // Log in to get JWT token
            var loginRequest = new LoginRequest
            {
                Email = email,
                Password = "Password123"
            };
            var loginResponse = await _client.PostAsJsonAsync("/api/auth/login", loginRequest);
            var authResult = await loginResponse.Content.ReadFromJsonAsync<AuthResponse>();
            
            Assert.NotNull(authResult);
            Assert.NotEmpty(authResult.Token);
            
            return authResult.Token;
        }

        [Fact]
        public async Task TodoLifecycle_ShouldSucceed()
        {
            // 1. Arrange: Authenticate and set JWT Authorization header
            var token = await AuthenticateAsync();
            _client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

            // 2. Act & Assert: CREATE TODO (POST /api/todos)
            var createDto = new CreateTodoTaskDto
            {
                Title = "Learn advanced integration testing",
                StartTime = DateTime.UtcNow.AddHours(1),
                EndTime = DateTime.UtcNow.AddHours(3)
            };

            var createResponse = await _client.PostAsJsonAsync("/api/todos", createDto);
            Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);

            var createdTodo = await createResponse.Content.ReadFromJsonAsync<TodoTaskDto>();
            Assert.NotNull(createdTodo);
            Assert.NotEqual(Guid.Empty, createdTodo.Id);
            Assert.Equal(createDto.Title, createdTodo.Title);
            Assert.False(createdTodo.IsCompleted);

            // 3. Act & Assert: GET TODOS (GET /api/todos)
            var getResponse = await _client.GetAsync("/api/todos");
            Assert.Equal(HttpStatusCode.OK, getResponse.StatusCode);

            var todos = await getResponse.Content.ReadFromJsonAsync<List<TodoTaskDto>>();
            Assert.NotNull(todos);
            Assert.NotEmpty(todos);
            Assert.Contains(todos, t => t.Id == createdTodo.Id);

            // 4. Act & Assert: GET TODO BY ID (GET /api/todos/{id})
            var getByIdResponse = await _client.GetAsync($"/api/todos/{createdTodo.Id}");
            Assert.Equal(HttpStatusCode.OK, getByIdResponse.StatusCode);

            var fetchedTodo = await getByIdResponse.Content.ReadFromJsonAsync<TodoTaskDto>();
            Assert.NotNull(fetchedTodo);
            Assert.Equal(createdTodo.Id, fetchedTodo.Id);
            Assert.Equal(createdTodo.Title, fetchedTodo.Title);

            // 5. Act & Assert: TOGGLE STATUS (PATCH /api/todos/{id}/toggle)
            var toggleResponse = await _client.PatchAsync($"/api/todos/{createdTodo.Id}/toggle", null);
            Assert.Equal(HttpStatusCode.OK, toggleResponse.StatusCode);

            var toggledTodo = await toggleResponse.Content.ReadFromJsonAsync<TodoTaskDto>();
            Assert.NotNull(toggledTodo);
            Assert.Equal(createdTodo.Id, toggledTodo.Id);
            Assert.True(toggledTodo.IsCompleted);

            // 6. Act & Assert: DELETE TODO (DELETE /api/todos/{id})
            var deleteResponse = await _client.DeleteAsync($"/api/todos/{createdTodo.Id}");
            Assert.Equal(HttpStatusCode.NoContent, deleteResponse.StatusCode);

            // Verify it was deleted (should return 404 NotFound)
            var getDeletedResponse = await _client.GetAsync($"/api/todos/{createdTodo.Id}");
            Assert.Equal(HttpStatusCode.NotFound, getDeletedResponse.StatusCode);
        }

        [Fact]
        public async Task GetTodos_WithoutAuth_ShouldReturnUnauthorized()
        {
            // Arrange: Clear authorization headers
            _client.DefaultRequestHeaders.Authorization = null;

            // Act
            var response = await _client.GetAsync("/api/todos");

            // Assert
            Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
        }
    }
}
