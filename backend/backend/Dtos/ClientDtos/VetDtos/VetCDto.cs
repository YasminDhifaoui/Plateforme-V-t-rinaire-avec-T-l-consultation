﻿namespace backend.Dtos.ClientDtos.VetDtos
{
    public class VetCDto
    {
        public Guid Id {  get; set; } 
        public string UserName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty ;
        public string PhoneNumber { get; set; } = string.Empty;
        public string Address { get; set; } = string.Empty ;

 
    }
}
