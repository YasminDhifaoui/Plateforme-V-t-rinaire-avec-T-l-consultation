using System.Threading.Tasks;

namespace backend.Services
{
    public interface IFcmTokenService
    {
        Task SaveTokenAsync(string userId, string token, string appType);
        Task<string?> GetTokenAsync(string userId, string appType);
    }
}