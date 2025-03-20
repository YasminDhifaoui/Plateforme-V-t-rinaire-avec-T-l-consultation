using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class deleteFKofUser : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Animals_AspNetUsers_OwnerId",
                table: "Animals");

            migrationBuilder.DropForeignKey(
                name: "FK_Commandes_AspNetUsers_ClientId",
                table: "Commandes");

            migrationBuilder.DropIndex(
                name: "IX_Commandes_ClientId",
                table: "Commandes");

            migrationBuilder.DropIndex(
                name: "IX_Animals_OwnerId",
                table: "Animals");

            migrationBuilder.DropColumn(
                name: "ClientId",
                table: "Commandes");

            migrationBuilder.DropColumn(
                name: "OwnerId",
                table: "Animals");

            migrationBuilder.AddColumn<Guid>(
                name: "AppUserId",
                table: "Animals",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Animals_AppUserId",
                table: "Animals",
                column: "AppUserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Animals_AspNetUsers_AppUserId",
                table: "Animals",
                column: "AppUserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Animals_AspNetUsers_AppUserId",
                table: "Animals");

            migrationBuilder.DropIndex(
                name: "IX_Animals_AppUserId",
                table: "Animals");

            migrationBuilder.DropColumn(
                name: "AppUserId",
                table: "Animals");

            migrationBuilder.AddColumn<Guid>(
                name: "ClientId",
                table: "Commandes",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<Guid>(
                name: "OwnerId",
                table: "Animals",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.CreateIndex(
                name: "IX_Commandes_ClientId",
                table: "Commandes",
                column: "ClientId");

            migrationBuilder.CreateIndex(
                name: "IX_Animals_OwnerId",
                table: "Animals",
                column: "OwnerId");

            migrationBuilder.AddForeignKey(
                name: "FK_Animals_AspNetUsers_OwnerId",
                table: "Animals",
                column: "OwnerId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Commandes_AspNetUsers_ClientId",
                table: "Commandes",
                column: "ClientId",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
