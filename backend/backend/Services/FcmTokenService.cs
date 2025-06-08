using System;
using System.Collections.Concurrent;
using System.Threading.Tasks;

namespace backend.Services
{
    public class FcmTokenService : IFcmTokenService
    {
        // In-memory store for FCM tokens. REPLACE WITH A DATABASE IN PRODUCTION!
        // Key format: $"{userId}-{appType}", Value: FCM Token string
        private readonly ConcurrentDictionary<string, string> _fcmTokens = new();

        public Task SaveTokenAsync(string userId, string token, string appType)
        {
            var key = $"{userId}-{appType}";
            _fcmTokens.AddOrUpdate(key, token, (oldKey, oldValue) => token);
            Console.WriteLine($"[Backend FCM TokenService] Saved/Updated token for user {userId} ({appType}). Current token count: {_fcmTokens.Count}");
            return Task.CompletedTask;
        }

        public Task<string?> GetTokenAsync(string userId, string appType)
        {
            var key = $"{userId}-{appType}";
            _fcmTokens.TryGetValue(key, out var token);
            Console.WriteLine($"[Backend FCM TokenService] Retrieved token for user {userId} ({appType}): {(token != null ? "Found" : "Not Found")}");
            return Task.FromResult(token);
        }
    }
}