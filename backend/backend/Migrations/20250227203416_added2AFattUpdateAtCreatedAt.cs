using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace backend.Migrations
{
    /// <inheritdoc />
    public partial class added2AFattUpdateAtCreatedAt : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Vaccinations_Animals_AnimalId",
                table: "Vaccinations");

            migrationBuilder.DropColumn(
                name: "antecedentsMedicaux",
                table: "Animals");

            migrationBuilder.DropColumn(
                name: "espece",
                table: "Animals");

            migrationBuilder.RenameColumn(
                name: "name",
                table: "Vaccinations",
                newName: "Name");

            migrationBuilder.RenameColumn(
                name: "date",
                table: "Vaccinations",
                newName: "Date");

            migrationBuilder.RenameColumn(
                name: "username",
                table: "Users",
                newName: "Username");

            migrationBuilder.RenameColumn(
                name: "role",
                table: "Users",
                newName: "Role");

            migrationBuilder.RenameColumn(
                name: "password",
                table: "Users",
                newName: "Password");

            migrationBuilder.RenameColumn(
                name: "email",
                table: "Users",
                newName: "Email");

            migrationBuilder.RenameColumn(
                name: "name",
                table: "Animals",
                newName: "Name");

            migrationBuilder.RenameColumn(
                name: "allergies",
                table: "Animals",
                newName: "Allergies");

            migrationBuilder.RenameColumn(
                name: "age",
                table: "Animals",
                newName: "Age");

            migrationBuilder.RenameColumn(
                name: "sexe",
                table: "Animals",
                newName: "Sex");

            migrationBuilder.RenameColumn(
                name: "race",
                table: "Animals",
                newName: "MedicalHistory");

            migrationBuilder.RenameColumn(
                name: "idProprietaire",
                table: "Animals",
                newName: "OwnerId");

            migrationBuilder.AlterColumn<string>(
                name: "Name",
                table: "Vaccinations",
                type: "character varying(100)",
                maxLength: 100,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<int>(
                name: "AnimalId",
                table: "Vaccinations",
                type: "integer",
                nullable: false,
                defaultValue: 0,
                oldClrType: typeof(int),
                oldType: "integer",
                oldNullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Vaccinations",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Vaccinations",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AlterColumn<string>(
                name: "Username",
                table: "Users",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<string>(
                name: "Email",
                table: "Users",
                type: "text",
                nullable: false,
                oldClrType: typeof(int),
                oldType: "integer");

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Users",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<string>(
                name: "TwoFactorCode",
                table: "Users",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "TwoFactorEnabled",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "TwoFactorExpiration",
                table: "Users",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Users",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AlterColumn<string>(
                name: "Name",
                table: "Animals",
                type: "character varying(100)",
                maxLength: 100,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AddColumn<string>(
                name: "Breed",
                table: "Animals",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Animals",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

            migrationBuilder.AddColumn<string>(
                name: "Species",
                table: "Animals",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<DateTime>(
                name: "UpdatedAt",
                table: "Animals",
                type: "timestamp with time zone",
                nullable: false,
                defaultValue: new DateTime(1, 1, 1, 0, 0, 0, 0, DateTimeKind.Unspecified));

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

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Animals_Users_OwnerId",
                table: "Animals");

            migrationBuilder.DropForeignKey(
                name: "FK_Vaccinations_Animals_AnimalId",
                table: "Vaccinations");

            migrationBuilder.DropIndex(
                name: "IX_Animals_OwnerId",
                table: "Animals");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Vaccinations");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Vaccinations");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "TwoFactorCode",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "TwoFactorEnabled",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "TwoFactorExpiration",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "Breed",
                table: "Animals");

            migrationBuilder.DropColumn(
                name: "CreatedAt",
                table: "Animals");

            migrationBuilder.DropColumn(
                name: "Species",
                table: "Animals");

            migrationBuilder.DropColumn(
                name: "UpdatedAt",
                table: "Animals");

            migrationBuilder.RenameColumn(
                name: "Name",
                table: "Vaccinations",
                newName: "name");

            migrationBuilder.RenameColumn(
                name: "Date",
                table: "Vaccinations",
                newName: "date");

            migrationBuilder.RenameColumn(
                name: "Username",
                table: "Users",
                newName: "username");

            migrationBuilder.RenameColumn(
                name: "Role",
                table: "Users",
                newName: "role");

            migrationBuilder.RenameColumn(
                name: "Password",
                table: "Users",
                newName: "password");

            migrationBuilder.RenameColumn(
                name: "Email",
                table: "Users",
                newName: "email");

            migrationBuilder.RenameColumn(
                name: "Name",
                table: "Animals",
                newName: "name");

            migrationBuilder.RenameColumn(
                name: "Allergies",
                table: "Animals",
                newName: "allergies");

            migrationBuilder.RenameColumn(
                name: "Age",
                table: "Animals",
                newName: "age");

            migrationBuilder.RenameColumn(
                name: "Sex",
                table: "Animals",
                newName: "sexe");

            migrationBuilder.RenameColumn(
                name: "OwnerId",
                table: "Animals",
                newName: "idProprietaire");

            migrationBuilder.RenameColumn(
                name: "MedicalHistory",
                table: "Animals",
                newName: "race");

            migrationBuilder.AlterColumn<string>(
                name: "name",
                table: "Vaccinations",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(100)",
                oldMaxLength: 100);

            migrationBuilder.AlterColumn<int>(
                name: "AnimalId",
                table: "Vaccinations",
                type: "integer",
                nullable: true,
                oldClrType: typeof(int),
                oldType: "integer");

            migrationBuilder.AlterColumn<string>(
                name: "username",
                table: "Users",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<int>(
                name: "email",
                table: "Users",
                type: "integer",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<string>(
                name: "name",
                table: "Animals",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(100)",
                oldMaxLength: 100);

            migrationBuilder.AddColumn<string>(
                name: "antecedentsMedicaux",
                table: "Animals",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "espece",
                table: "Animals",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddForeignKey(
                name: "FK_Vaccinations_Animals_AnimalId",
                table: "Vaccinations",
                column: "AnimalId",
                principalTable: "Animals",
                principalColumn: "Id");
        }
    }
}
