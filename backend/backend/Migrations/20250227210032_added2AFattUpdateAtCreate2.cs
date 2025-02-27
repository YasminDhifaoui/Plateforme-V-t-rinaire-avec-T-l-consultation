using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class added2AFattUpdateAtCreate2 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Animals_Users_OwnerId",
                table: "Animals");

            migrationBuilder.DropForeignKey(
                name: "FK_Vaccinations_Animals_AnimalId",
                table: "Vaccinations");

            migrationBuilder.DropIndex(
                name: "IX_Vaccinations_AnimalId",
                table: "Vaccinations");

            migrationBuilder.DropIndex(
                name: "IX_Animals_OwnerId",
                table: "Animals");

            migrationBuilder.DropColumn(
                name: "AnimalId",
                table: "Vaccinations");

            migrationBuilder.DropColumn(
                name: "OwnerId",
                table: "Animals");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "AnimalId",
                table: "Vaccinations",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "OwnerId",
                table: "Animals",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "IX_Vaccinations_AnimalId",
                table: "Vaccinations",
                column: "AnimalId");

            migrationBuilder.CreateIndex(
                name: "IX_Animals_OwnerId",
                table: "Animals",
                column: "OwnerId");

            migrationBuilder.AddForeignKey(
                name: "FK_Animals_Users_OwnerId",
                table: "Animals",
                column: "OwnerId",
                principalTable: "Users",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_Vaccinations_Animals_AnimalId",
                table: "Vaccinations",
                column: "AnimalId",
                principalTable: "Animals",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
