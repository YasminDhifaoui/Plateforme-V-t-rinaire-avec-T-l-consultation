using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class fixTheProduitsModel : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Produits_Categories_CategorieId",
                table: "Produits");

            migrationBuilder.DropForeignKey(
                name: "FK_Produits_Commandes_CommandeId",
                table: "Produits");

            migrationBuilder.DropIndex(
                name: "IX_Produits_CategorieId",
                table: "Produits");

            migrationBuilder.DropIndex(
                name: "IX_Produits_CommandeId",
                table: "Produits");

            migrationBuilder.DropColumn(
                name: "CategorieId",
                table: "Produits");

            migrationBuilder.DropColumn(
                name: "CommandeId",
                table: "Produits");

            migrationBuilder.RenameColumn(
                name: "Stock",
                table: "Produits",
                newName: "Available");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "Available",
                table: "Produits",
                newName: "Stock");

            migrationBuilder.AddColumn<Guid>(
                name: "CategorieId",
                table: "Produits",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.AddColumn<Guid>(
                name: "CommandeId",
                table: "Produits",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Produits_CategorieId",
                table: "Produits",
                column: "CategorieId");

            migrationBuilder.CreateIndex(
                name: "IX_Produits_CommandeId",
                table: "Produits",
                column: "CommandeId");

            migrationBuilder.AddForeignKey(
                name: "FK_Produits_Categories_CategorieId",
                table: "Produits",
                column: "CategorieId",
                principalTable: "Categories",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Produits_Commandes_CommandeId",
                table: "Produits",
                column: "CommandeId",
                principalTable: "Commandes",
                principalColumn: "Id");
        }
    }
}
