defmodule Api.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:first_name, :string, null: false)
      add(:last_name, :string, null: false)
      add(:birthdate, :date, null: false)
      add(:gender, :string, null: false)

      timestamps()
    end

    create(constraint(:users, :gender_must_be_valid, check: "gender IN ('male', 'female')"))
  end
end
