using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class seperateConsAndRdv : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Consultations_RendezVous_RendezVousId",
                table: "Consultations");

            migrationBuilder.DropIndex(
                name: "IX_Consultations_RendezVousId",
                table: "Consultations");

            migrationBuilder.DropColumn(
                name: "RendezVousId",
                table: "Consultations");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "RendezVousId",
                table: "Consultations",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"));

            migrationBuilder.CreateIndex(
                name: "IX_Consultations_RendezVousId",
                table: "Consultations",
                column: "RendezVousId");

            migrationBuilder.AddForeignKey(
                name: "FK_Consultations_RendezVous_RendezVousId",
                table: "Consultations",
                column: "RendezVousId",
                principalTable: "RendezVous",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
