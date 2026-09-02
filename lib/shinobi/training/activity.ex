defmodule Shinobi.Training.Activity do
  use Ecto.Schema
  import Ecto.Changeset

  alias Shinobi.Accounts.User
  alias Shinobi.Training.PersonalRecord

  @measurement_types ~w(time time_weight rounds rounds_weight reps reps_weight)

  schema "activities" do
    field :name, :string
    field :description, :string
    field :measurement_type, :string

    belongs_to :user, User
    has_many :personal_records, PersonalRecord

    timestamps(type: :utc_datetime)
  end

  def measurement_types, do: @measurement_types

  def measurement_options do
    [
      {"Tempo", "time"},
      {"Tempo + peso", "time_weight"},
      {"Voltas", "rounds"},
      {"Voltas + peso", "rounds_weight"},
      {"Repeticoes", "reps"},
      {"Repeticoes + peso", "reps_weight"}
    ]
  end

  def measurement_label("time"), do: "Tempo"
  def measurement_label("time_weight"), do: "Tempo + peso"
  def measurement_label("rounds"), do: "Voltas"
  def measurement_label("rounds_weight"), do: "Voltas + peso"
  def measurement_label("reps"), do: "Repeticoes"
  def measurement_label("reps_weight"), do: "Repeticoes + peso"
  def measurement_label(_), do: "Medida"

  def weighted?("time_weight"), do: true
  def weighted?("rounds_weight"), do: true
  def weighted?("reps_weight"), do: true
  def weighted?(_), do: false

  def time_based?("time"), do: true
  def time_based?("time_weight"), do: true
  def time_based?(_), do: false

  def rounds_based?("rounds"), do: true
  def rounds_based?("rounds_weight"), do: true
  def rounds_based?(_), do: false

  def reps_based?("reps"), do: true
  def reps_based?("reps_weight"), do: true
  def reps_based?(_), do: false

  def changeset(activity, attrs) do
    activity
    |> cast(attrs, [:name, :description, :measurement_type])
    |> validate_required([:name, :measurement_type])
    |> validate_length(:name, max: 120)
    |> validate_length(:description, max: 1_000)
    |> validate_inclusion(:measurement_type, @measurement_types)
  end
end
