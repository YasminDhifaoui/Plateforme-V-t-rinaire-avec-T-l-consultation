using System.ComponentModel.DataAnnotations.Schema;

namespace backend.Models
{
    public class Admin
    {
        public Guid AdminId {get ; set;} = Guid.NewGuid();

        [ForeignKey("AppUser")]
        public Guid AppUserId { get; set; }
    }
}
