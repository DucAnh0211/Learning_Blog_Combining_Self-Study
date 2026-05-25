using backend_assignment_and_management_project.Application.Interfaces;
using backend_assignment_and_management_project.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;

namespace backend_assignment_and_management_project.Infrastructure.Services
{
    public class DeadlineNotificationService : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<DeadlineNotificationService> _logger;
        private readonly TimeSpan _checkInterval = TimeSpan.FromMinutes(5);

        public DeadlineNotificationService(
            IServiceProvider serviceProvider,
            ILogger<DeadlineNotificationService> logger)
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            _logger.LogInformation("Deadline Notification Service is starting.");

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await CheckDeadlinesAsync(stoppingToken);
                }
                catch (OperationCanceledException)
                {
                    // Prevent logging error when service is shutting down
                    break;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error occurred while checking deadlines.");
                }

                try
                {
                    await Task.Delay(_checkInterval, stoppingToken);
                }
                catch (OperationCanceledException)
                {
                    break;
                }
            }

            _logger.LogInformation("Deadline Notification Service is stopping.");
        }

        private async Task CheckDeadlinesAsync(CancellationToken stoppingToken)
        {
            using (var scope = _serviceProvider.CreateScope())
            {
                var context = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
                var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();

                var now = DateTime.UtcNow;
                var oneHourLater = now.AddHours(1);

                // 1. Check for approaching deadlines (within 1 hour)
                var approachingTasks = await context.TodoTasks
                    .Where(t => !t.IsCompleted && t.EndTime > now && t.EndTime <= oneHourLater)
                    .ToListAsync(stoppingToken);

                foreach (var task in approachingTasks)
                {
                    // Check if already notified
                    var exists = await context.Notifications
                        .AnyAsync(n => n.UserId == task.UserId && n.TargetId == task.Id && n.Type == "DeadlineApproaching", stoppingToken);

                    if (!exists)
                    {
                        // Chuyển đổi từ UTC sang múi giờ Việt Nam (UTC+7) để hiển thị chính xác giờ cho người dùng
                        var localEndTime = task.EndTime.Value.AddHours(7);
                        
                        await notificationService.CreateNotificationAsync(
                            task.UserId,
                            "Sắp hết hạn!",
                            $"Công việc '{task.Title}' sẽ hết hạn vào lúc {localEndTime:HH:mm}.",
                            "DeadlineApproaching",
                            task.Id
                        );
                    }
                }

                // 2. Check for expired deadlines
                var expiredTasks = await context.TodoTasks
                    .Where(t => !t.IsCompleted && t.EndTime <= now)
                    .ToListAsync(stoppingToken);

                foreach (var task in expiredTasks)
                {
                    // Check if already notified
                    var exists = await context.Notifications
                        .AnyAsync(n => n.UserId == task.UserId && n.TargetId == task.Id && n.Type == "DeadlineExpired", stoppingToken);

                    if (!exists)
                    {
                        await notificationService.CreateNotificationAsync(
                            task.UserId,
                            "Đã hết hạn!",
                            $"Công việc '{task.Title}' đã quá hạn deadline.",
                            "DeadlineExpired",
                            task.Id
                        );
                    }
                }
            }
        }
    }
}
