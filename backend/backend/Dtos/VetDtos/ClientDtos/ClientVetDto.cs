﻿namespace backend.Dtos.VetDtos.ClientDtos
{
    public class ClientVetDto
    {
        public Guid Id { get; set; }
        public string Username { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string PhoneNumber { get; set; } = string.Empty;
        public string Address {  get; set; } = string.Empty;
    }
}
