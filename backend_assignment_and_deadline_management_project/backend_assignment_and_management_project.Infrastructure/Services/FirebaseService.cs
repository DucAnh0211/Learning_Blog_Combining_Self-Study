using backend_assignment_and_management_project.Application.Interfaces;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Logging;
using System;
using System.IO;
using System.Threading.Tasks;

namespace backend_assignment_and_management_project.Infrastructure.Services
{
    public class FirebaseService : IFirebaseService
    {
        private readonly ILogger<FirebaseService> _logger;
        private readonly bool _isInitialized;

        public FirebaseService(ILogger<FirebaseService> logger)
        {
            _logger = logger;
            
            try
            {
                // Tìm file cấu hình Firebase Service Account
                // Thử tìm ở thư mục chạy hiện tại hoặc thư mục bin
                string credentialPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "firebase-service-account.json");
                if (!File.Exists(credentialPath))
                {
                    credentialPath = Path.Combine(Directory.GetCurrentDirectory(), "firebase-service-account.json");
                }

                if (File.Exists(credentialPath))
                {
                    if (FirebaseApp.DefaultInstance == null)
                    {
                        FirebaseApp.Create(new AppOptions()
                        {
                            Credential = GoogleCredential.FromFile(credentialPath)
                        });
                        _logger.LogInformation("[FirebaseService] Firebase Admin SDK initialized successfully using: {Path}", credentialPath);
                    }
                    _isInitialized = true;
                }
                else
                {
                    _logger.LogWarning("[FirebaseService] firebase-service-account.json was not found at '{Path}'. FCM push notifications will be simulated/logged but NOT sent to Google.", credentialPath);
                    _isInitialized = false;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[FirebaseService] Failed to initialize Firebase Admin SDK.");
                _isInitialized = false;
            }
        }

        public async Task SendPushNotificationAsync(string fcmToken, string title, string body, string type, string? targetId = null)
        {
            if (string.IsNullOrEmpty(fcmToken))
            {
                _logger.LogWarning("[FirebaseService] Cannot send FCM push notification because token is null or empty.");
                return;
            }

            _logger.LogInformation("[FirebaseService] Sending FCM notification to token: {Token:cool}. Title: '{Title}', Body: '{Body}'", 
                fcmToken.Length > 15 ? fcmToken.Substring(0, 15) + "..." : fcmToken, title, body);

            if (!_isInitialized)
            {
                _logger.LogWarning("[FirebaseService] Firebase is not initialized (missing credentials JSON). Skipping FCM send.");
                return;
            }

            try
            {
                var message = new Message()
                {
                    Token = fcmToken,
                    Notification = new Notification()
                    {
                        Title = title,
                        Body = body
                    },
                    Data = new Dictionary<string, string>()
                    {
                        { "type", type },
                        { "targetId", targetId ?? string.Empty },
                        { "click_action", "FLUTTER_NOTIFICATION_CLICK" }
                    },
                    Android = new AndroidConfig()
                    {
                        Priority = Priority.High,
                        Notification = new AndroidNotification()
                        {
                            Sound = "default",
                            ClickAction = "FLUTTER_NOTIFICATION_CLICK"
                        }
                    }
                };

                string response = await FirebaseMessaging.DefaultInstance.SendAsync(message);
                _logger.LogInformation("[FirebaseService] Successfully sent FCM message. Response ID: {ResponseId}", response);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "[FirebaseService] Error sending FCM push notification.");
            }
        }
    }
}
