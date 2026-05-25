using backend_assignment_and_management_project.Application.DTOs;

namespace backend_assignment_and_management_project.Application.Interfaces
{
    public interface IRealtimeNotificationService
    {
        Task SendNotificationToUserAsync(Guid userId, NotificationDto notification);
    }
}
