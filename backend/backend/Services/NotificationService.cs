using FirebaseAdmin.Messaging;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

// IMPORTANT: Do NOT include this 'using' directive, it causes conflicts with FirebaseAdmin 3.x
// using Google.Apis.Firebasecloudmessaging.v1.Data;

// MAKE SURE THIS NAMESPACE MATCHES YOUR PROJECT'S ACTUAL NAMESPACE AND FOLDER STRUCTURE!
// For example, if your project's default namespace is 'backend' and this file is in 'Services' folder,
// it should be 'namespace backend.Services'
namespace backend.Services

{
    public class NotificationService : INotificationService
    {
        private readonly IFcmTokenService _fcmTokenService;

        public NotificationService(IFcmTokenService fcmTokenService)
        {
            _fcmTokenService = fcmTokenService;
        }

        /// <summary>
        /// Sends a chat message notification via FCM.
        /// This method aligns with your Flutter app's `sendChatMessageNotification` call.
        /// </summary>
        public async Task SendChatMessageNotificationAsync(
            string recipientId,
            string recipientAppType, // <<< Directly use this parameter's value
            string senderId,
            string senderName,
            string messageContent,
            string? fileUrl,
            string? fileName,
            string? fileType)
        {
            // --- REMOVE THIS LINE: You were re-inferring the type incorrectly ---
            // string recipientAppType = recipientId.StartsWith("vet") ? "vet" : "client";
            // --- END REMOVAL ---

            // Now, 'recipientAppType' here correctly holds the value sent by Flutter (e.g., "vet")
            var recipientFcmToken = await _fcmTokenService.GetTokenAsync(recipientId, recipientAppType);

            if (string.IsNullOrEmpty(recipientFcmToken))
            {
                Console.WriteLine($"[Backend NotificationService] Aucun jeton FCM trouvé pour le destinataire {recipientId} (type: {recipientAppType}). Impossible d'envoyer le message de chat.");
                return;
            }

            // --- Create the mutable data dictionary for the FCM message ---
            var dataPayload = new Dictionary<string, string>
            {
                {"type", "chat_message"}, // This MUST match 'chat_message' in your Flutter app's logic
                {"sender_id", senderId},
                {"sender_name", senderName},
                {"message_content", messageContent}
            };

            // Add file details to data payload if available.
            if (!string.IsNullOrEmpty(fileUrl)) dataPayload["file_url"] = fileUrl;
            if (!string.IsNullOrEmpty(fileName)) dataPayload["file_name"] = fileName;
            if (!string.IsNullOrEmpty(fileType)) dataPayload["file_type"] = fileType;
            // --- End creating the mutable data dictionary ---

            var message = new Message()
            {
                Notification = new Notification // FirebaseAdmin.Messaging.Notification
                {
                    Title = $"Nouveau message de {senderName}",
                    Body = messageContent
                },
                Data = dataPayload, // Attach your custom data payload
                Token = recipientFcmToken, // The FCM token for the specific device
                Android = new AndroidConfig // Android-specific settings
                {
                    Priority = Priority.High, // Ensures the notification is treated as urgent
                    Notification = new AndroidNotification
                    {
                        ChannelId = "high_importance_channel_client", // CRITICAL: MUST match your Flutter app's channel ID
                        Sound = "default", // Plays default sound on Android
                        Visibility = NotificationVisibility.PUBLIC
                    }
                },
               
            };

            try
            {
                string response = await FirebaseMessaging.DefaultInstance.SendAsync(message);
                Console.WriteLine($"[Backend NotificationService] Message de chat envoyé avec succès à {recipientId} (type: {recipientAppType}) : {response}");
            }
            catch (FirebaseMessagingException ex)
            {
                Console.WriteLine($"[Backend NotificationService Erreur] Échec de l'envoi du message de chat à {recipientId} (type: {recipientAppType}) : {ex.Message} (Code : {ex.ErrorCode})");
                // TODO: Implement robust error handling, e.g., delete invalid/expired FCM tokens from storage
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Backend NotificationService Erreur] Une erreur inattendue s'est produite lors de l'envoi du message de chat à {recipientId} (type: {recipientAppType}) : {ex.Message}");
            }
        }

        /// <summary>
        /// Sends an incoming call notification via FCM.
        /// NOTE: This method also needs a `recipientAppType` parameter to be fully robust,
        /// similar to `SendChatMessageNotificationAsync`.
        /// </summary>
        public async Task SendIncomingCallNotificationAsync(
            string recipientId,
            string callerId,
            string callerName)
        {
            // For now, this still infers. Ideally, you'd pass recipientAppType from Flutter for calls too.
            string inferredRecipientAppType = recipientId.StartsWith("vet") ? "vet" : "client";

            var recipientFcmToken = await _fcmTokenService.GetTokenAsync(recipientId, inferredRecipientAppType);

            if (string.IsNullOrEmpty(recipientFcmToken))
            {
                Console.WriteLine($"[Backend NotificationService] Aucun jeton FCM trouvé pour le destinataire {recipientId} (type: {inferredRecipientAppType}). Impossible d'envoyer la notification d'appel entrant.");
                return;
            }

            var dataPayload = new Dictionary<string, string>
            {
                {"type", "incoming_call"},
                {"caller_id", callerId},
                {"caller_name", callerName}
            };

            var message = new Message()
            {
                Notification = new Notification
                {
                    Title = "Appel entrant",
                    Body = $"Appel de {callerName}",
                },
                Data = dataPayload,
                Token = recipientFcmToken,
                Android = new AndroidConfig
                {
                    Priority = Priority.High,
                    Notification = new AndroidNotification
                    {
                        ChannelId = "high_importance_channel_client",
                        Sound = "default",
                        Visibility = NotificationVisibility.PUBLIC
                    }
                },
               
            };

            try
            {
                string response = await FirebaseMessaging.DefaultInstance.SendAsync(message);
                Console.WriteLine($"[Backend NotificationService] Notification d'appel entrant envoyée avec succès à {recipientId} (type: {inferredRecipientAppType}) : {response}");
            }
            catch (FirebaseMessagingException ex) { /* ... */ }
            catch (Exception ex) { /* ... */ }
        }
    }
}