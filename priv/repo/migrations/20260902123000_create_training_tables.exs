defmodule Shinobi.Repo.Migrations.CreateTrainingTables do
  use Ecto.Migration

  def change do
    create table(:activities) do
      add :user_id, references(:users, on_delete: :delete_all)
      add :name, :string, null: false
      add :description, :text
      add :measurement_type, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create index(:activities, [:user_id])
    create index(:activities, [:measurement_type])

    create table(:personal_records) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :activity_id, references(:activities, on_delete: :delete_all), null: false
      add :performed_on, :date, null: false
      add :duration_seconds, :integer
      add :rounds, :decimal, precision: 10, scale: 2
      add :repetitions, :integer
      add :weight_kg, :decimal, precision: 10, scale: 2
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:personal_records, [:user_id])
    create index(:personal_records, [:activity_id])
    create index(:personal_records, [:user_id, :performed_on])
  end
end
