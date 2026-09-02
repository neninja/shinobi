defmodule Shinobi.Training.PersonalRecord do
  use Ecto.Schema
  import Ecto.Changeset

  alias Shinobi.Accounts.User
  alias Shinobi.Training.Activity

  schema "personal_records" do
    field :performed_on, :date
    field :duration_seconds, :integer
    field :rounds, :decimal
    field :repetitions, :integer
    field :weight_kg, :decimal
    field :notes, :string
    field :time_minutes, :integer, virtual: true
    field :time_seconds, :integer, virtual: true

    belongs_to :user, User
    belongs_to :activity, Activity

    timestamps(type: :utc_datetime)
  end

  def changeset(record, attrs, %Activity{} = activity) do
    record
    |> with_duration_parts()
    |> cast(attrs, [
      :performed_on,
      :time_minutes,
      :time_seconds,
      :rounds,
      :repetitions,
      :weight_kg,
      :notes
    ])
    |> validate_required([:performed_on])
    |> validate_length(:notes, max: 1_000)
    |> normalize_result_fields(activity.measurement_type)
    |> validate_result(activity.measurement_type)
  end

  def with_duration_parts(%__MODULE__{duration_seconds: nil} = record) do
    %{record | time_minutes: nil, time_seconds: nil}
  end

  def with_duration_parts(%__MODULE__{duration_seconds: duration_seconds} = record) do
    %{record | time_minutes: div(duration_seconds, 60), time_seconds: rem(duration_seconds, 60)}
  end

  def result_summary(
        %__MODULE__{activity: %Activity{measurement_type: measurement_type}} = record
      ) do
    case measurement_type do
      "time" ->
        format_duration(record.duration_seconds)

      "time_weight" ->
        "#{format_duration(record.duration_seconds)} / #{format_weight(record.weight_kg)}"

      "rounds" ->
        "#{format_decimal(record.rounds)} voltas"

      "rounds_weight" ->
        "#{format_decimal(record.rounds)} voltas / #{format_weight(record.weight_kg)}"

      "reps" ->
        "#{record.repetitions} reps"

      "reps_weight" ->
        "#{record.repetitions} reps / #{format_weight(record.weight_kg)}"

      _ ->
        "-"
    end
  end

  def format_duration(nil), do: "-"

  def format_duration(duration_seconds) when is_integer(duration_seconds) do
    minutes = div(duration_seconds, 60)
    seconds = rem(duration_seconds, 60)

    if minutes >= 60 do
      hours = div(minutes, 60)
      remaining_minutes = rem(minutes, 60)
      "#{hours}:#{pad_time(remaining_minutes)}:#{pad_time(seconds)}"
    else
      "#{minutes}:#{pad_time(seconds)}"
    end
  end

  def format_weight(nil), do: "-"
  def format_weight(weight), do: "#{format_decimal(weight)} kg"

  def format_decimal(nil), do: "-"

  def format_decimal(%Decimal{} = decimal) do
    decimal
    |> Decimal.normalize()
    |> Decimal.to_string(:normal)
  end

  def format_decimal(value), do: to_string(value)

  defp normalize_result_fields(changeset, measurement_type) do
    changeset
    |> maybe_put_duration(measurement_type)
    |> maybe_clear_field(:rounds, Activity.rounds_based?(measurement_type))
    |> maybe_clear_field(:repetitions, Activity.reps_based?(measurement_type))
    |> maybe_clear_field(:weight_kg, Activity.weighted?(measurement_type))
  end

  defp maybe_put_duration(changeset, measurement_type) do
    if Activity.time_based?(measurement_type) do
      minutes = get_field(changeset, :time_minutes) || 0
      seconds = get_field(changeset, :time_seconds) || 0
      put_change(changeset, :duration_seconds, minutes * 60 + seconds)
    else
      put_change(changeset, :duration_seconds, nil)
    end
  end

  defp maybe_clear_field(changeset, _field, true), do: changeset
  defp maybe_clear_field(changeset, field, false), do: put_change(changeset, field, nil)

  defp validate_result(changeset, measurement_type) do
    changeset
    |> validate_time(Activity.time_based?(measurement_type))
    |> validate_rounds(Activity.rounds_based?(measurement_type))
    |> validate_repetitions(Activity.reps_based?(measurement_type))
    |> validate_weight(Activity.weighted?(measurement_type))
  end

  defp validate_time(changeset, true) do
    changeset
    |> validate_required([:time_minutes, :time_seconds])
    |> validate_number(:time_minutes, greater_than_or_equal_to: 0)
    |> validate_number(:time_seconds, greater_than_or_equal_to: 0, less_than: 60)
    |> validate_duration_total()
  end

  defp validate_time(changeset, false), do: changeset

  defp validate_duration_total(changeset) do
    case get_field(changeset, :duration_seconds) do
      duration_seconds when is_integer(duration_seconds) and duration_seconds > 0 ->
        changeset

      _ ->
        add_error(changeset, :time_minutes, "informe um tempo maior que zero")
    end
  end

  defp validate_rounds(changeset, true) do
    changeset
    |> validate_required([:rounds])
    |> validate_number(:rounds, greater_than: 0)
  end

  defp validate_rounds(changeset, false), do: changeset

  defp validate_repetitions(changeset, true) do
    changeset
    |> validate_required([:repetitions])
    |> validate_number(:repetitions, greater_than: 0)
  end

  defp validate_repetitions(changeset, false), do: changeset

  defp validate_weight(changeset, true) do
    changeset
    |> validate_required([:weight_kg])
    |> validate_number(:weight_kg, greater_than: 0)
  end

  defp validate_weight(changeset, false), do: changeset

  defp pad_time(value) when value < 10, do: "0#{value}"
  defp pad_time(value), do: to_string(value)
end
