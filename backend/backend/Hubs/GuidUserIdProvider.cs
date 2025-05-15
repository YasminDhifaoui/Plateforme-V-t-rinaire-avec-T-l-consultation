using Microsoft.AspNetCore.SignalR;

public class GuidUserIdProvider : IUserIdProvider
{
    public string GetUserId(HubConnectionContext connection)
    {
        // You must ensure the user claims contain their ID as a GUID string
        return connection.User?.FindFirst("Id")?.Value;
    }
}
