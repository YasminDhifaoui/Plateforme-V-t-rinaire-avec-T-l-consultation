using System.Threading.Tasks;

namespace backend.Services
{
    public interface INotificationService
    {
        Task SendChatMessageNotificationAsync(
            string recipientId,
            string recipientapptype,
            string senderId,
            string senderName,
            string messageContent,
            string? fileUrl,
            string? fileName,
            string? fileType
        );

        Task SendIncomingCallNotificationAsync(
            string recipientId,
            string callerId,
            string callerName
        );
    }
}