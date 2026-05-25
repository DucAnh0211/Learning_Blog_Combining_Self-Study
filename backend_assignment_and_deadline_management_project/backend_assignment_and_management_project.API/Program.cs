using System.Text;
using backend_assignment_and_management_project.Application.Interfaces;
using backend_assignment_and_management_project.Infrastructure.Persistence;
using backend_assignment_and_management_project.Infrastructure.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.AspNetCore.HttpOverrides;
using Microsoft.OpenApi.Models;
using backend_assignment_and_management_project.Domain.Entities;
using backend_assignment_and_management_project.API.Hubs;

var builder = WebApplication.CreateBuilder(args);

// 1. Thêm Controller
builder.Services.AddControllers();

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        builder =>
        {
            builder.AllowAnyOrigin()
                   .AllowAnyMethod()
                   .AllowAnyHeader();
        });
});

// 2. Cấu hình OpenAPI/Swagger với hỗ trợ JWT Bearer
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Assignment and Deadline Management API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Example: \"Authorization: Bearer {token}\"",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
            },
            new string[] { }
        }
    });
});

// 3. ĐĂNG KÝ DBCONTEXT KẾT NỐI POSTGRESQL
if (builder.Environment.IsEnvironment("Testing"))
{
    builder.Services.AddDbContext<ApplicationDbContext>(options =>
        options.UseInMemoryDatabase("InMemoryDbForTesting"));
}
else
{
    builder.Services.AddDbContext<ApplicationDbContext>(options =>
        options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));
}

// 4. Cấu hình Authentication JWT Bearer
var jwtSettings = builder.Configuration.GetSection("JWT");
var key = Encoding.ASCII.GetBytes(jwtSettings["Key"] ?? "superSecretKey1234567890123456"); // Fallback for safety

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.RequireHttpsMetadata = false;
    options.SaveToken = true;
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(key),
        ValidateIssuer = true,
        ValidIssuer = jwtSettings["Issuer"],
        ValidateAudience = true,
        ValidAudience = jwtSettings["Audience"],
        ValidateLifetime = true,
        ClockSkew = TimeSpan.Zero
    };

    // Configure JWT Bearer to support Query String for SignalR Connections
    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var accessToken = context.Request.Query["access_token"];
            var path = context.HttpContext.Request.Path;
            if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hubs"))
            {
                context.Token = accessToken;
            }
            return Task.CompletedTask;
        }
    };
});

// Register SignalR Services
builder.Services.AddSignalR();

// 5. Đăng ký các Service (Dependency Injection)
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IBlogService, BlogService>();
builder.Services.AddScoped<ISelfLearnService, SelfLearnService>();
builder.Services.AddScoped<ITodoService, TodoService>();
builder.Services.AddScoped<IStorageService, MinioStorageService>();
builder.Services.AddScoped<IUserActivityLogService, UserActivityLogService>();
builder.Services.AddScoped<IStatisticsService, StatisticsService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IRealtimeNotificationService, backend_assignment_and_management_project.API.Services.RealtimeNotificationService>();
builder.Services.AddHostedService<DeadlineNotificationService>();

var app = builder.Build();

// Cấu hình để nhận diện header từ Nginx Proxy
app.UseForwardedHeaders(new ForwardedHeadersOptions
{
    ForwardedHeaders = ForwardedHeaders.XForwardedFor | ForwardedHeaders.XForwardedProto
});

// 6. Cấu hình HTTP request pipeline
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<NotificationHub>("/hubs/notification");

// Seed Data
using (var scope = app.Services.CreateScope())
{
    var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
    context.Database.EnsureCreated();

    // 1. Seed Roles
    if (!context.Roles.Any())
    {
        context.Roles.AddRange(
            new Role { Name = "Admin" },
            new Role { Name = "User" }
        );
        context.SaveChanges();
    }

    var adminRole = context.Roles.First(r => r.Name == "Admin");

    // 2. Seed Admin User
    var adminUser = context.Users.FirstOrDefault(u => u.Email == "admin@gmail.com");
    if (adminUser == null)
    {
        adminUser = new User
        {
            Name = "System Admin",
            Email = "admin@gmail.com",
            Password = BCrypt.Net.BCrypt.HashPassword("admin123"),
            RoleId = adminRole.Id
        };
        context.Users.Add(adminUser);
        context.SaveChanges();
    }

    // 3. Seed Subjects
    await DbInitializer.Seed(context);
    
    var subjects = await context.Subjects.ToListAsync();

    // 4. Seed Posts (Commented out to stop mock data generation)
    // await DbInitializer.SeedPosts(context, adminUser);

    // 5. Cập nhật Schema cho Notifications & Gamification (Thêm cột mới nếu chưa có)
    Console.WriteLine($"[STARTUP] Active DB Provider: {context.Database.ProviderName}");
    if (context.Database.IsRelational())
    {
        await context.Database.ExecuteSqlRawAsync(@"
            DO $$ 
            BEGIN 
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='notifications' AND column_name='type') THEN
                    ALTER TABLE notifications ADD COLUMN type VARCHAR(50) DEFAULT 'System';
                END IF;
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='notifications' AND column_name='target_id') THEN
                    ALTER TABLE notifications ADD COLUMN target_id UUID;
                END IF;
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='notifications' AND column_name='actor_id') THEN
                    ALTER TABLE notifications ADD COLUMN actor_id UUID;
                END IF;
                
                -- Thêm cột level và points cho bảng users nếu chưa có
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='level') THEN
                    ALTER TABLE users ADD COLUMN level INTEGER DEFAULT 1;
                END IF;
                IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='users' AND column_name='points') THEN
                    ALTER TABLE users ADD COLUMN points INTEGER DEFAULT 0;
                END IF;
                
                -- Tạo bảng user_follows nếu chưa có
                CREATE TABLE IF NOT EXISTS user_follows (
                    follower_id UUID NOT NULL,
                    following_id UUID NOT NULL,
                    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (follower_id, following_id)
                );
            END $$;");
    };
}

app.Run();

public partial class Program { }
