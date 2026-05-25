using System.Threading.Tasks;

namespace backend_assignment_and_management_project.Application.Interfaces
{
    public interface IFirebaseService
    {
        Task SendPushNotificationAsync(string fcmToken, string title, string body, string type, string? targetId = null);
    }
}
