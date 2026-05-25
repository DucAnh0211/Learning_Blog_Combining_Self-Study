using backend_assignment_and_management_project.Application.DTOs;
using backend_assignment_and_management_project.Application.Interfaces;
using backend_assignment_and_management_project.API.Hubs;
using Microsoft.AspNetCore.SignalR;

namespace backend_assignment_and_management_project.API.Services
{
    public class RealtimeNotificationService : IRealtimeNotificationService
    {
        private readonly IHubContext<NotificationHub> _hubContext;
        private readonly ILogger<RealtimeNotificationService> _logger;

        public RealtimeNotificationService(
            IHubContext<NotificationHub> hubContext,
            ILogger<RealtimeNotificationService> logger)
        {
            _hubContext = hubContext;
            _logger = logger;
        }

        public async Task SendNotificationToUserAsync(Guid userId, NotificationDto notification)
        {
            try
            {
                _logger.LogInformation("Sending real-time SignalR notification to user {UserId}. Title: {Title}", userId, notification.Title);
                await _hubContext.Clients.User(userId.ToString()).SendAsync("ReceiveNotification", notification);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send real-time SignalR notification to user {UserId}", userId);
            }
        }
    }
}
