defmodule Shinobi.TrainingFixtures do
  @moduledoc """
  Test helpers for creating training data.
  """

  alias Shinobi.Repo
  alias Shinobi.Training
  alias Shinobi.Training.Activity

  def unique_activity_name, do: "Activity #{System.unique_integer([:positive])}"

  def valid_activity_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: unique_activity_name(),
      description: "Training test activity",
      measurement_type: "reps_weight"
    })
  end

  def activity_fixture(scope, attrs \\ %{}) do
    {:ok, activity} =
      scope
      |> Training.create_activity(valid_activity_attributes(attrs))

    activity
  end

  def global_activity_fixture(attrs \\ %{}) do
    attrs = valid_activity_attributes(attrs)

    %Activity{}
    |> Activity.changeset(attrs)
    |> Repo.insert!()
  end

  def valid_personal_record_attributes(activity, attrs \\ %{}) do
    activity
    |> measurement_attributes()
    |> Map.merge(%{
      "activity_id" => activity.id,
      "performed_on" => Date.to_iso8601(Date.utc_today()),
      "notes" => "Felt solid"
    })
    |> Map.merge(stringify_keys(attrs))
  end

  def personal_record_fixture(scope, activity, attrs \\ %{}) do
    {:ok, personal_record} =
      scope
      |> Training.create_personal_record(valid_personal_record_attributes(activity, attrs))

    personal_record
  end

  defp measurement_attributes(%Activity{measurement_type: "time"}) do
    %{"time_minutes" => "7", "time_seconds" => "42"}
  end

  defp measurement_attributes(%Activity{measurement_type: "time_weight"}) do
    %{"time_minutes" => "7", "time_seconds" => "42", "weight_kg" => "9"}
  end

  defp measurement_attributes(%Activity{measurement_type: "rounds"}) do
    %{"rounds" => "18.5"}
  end

  defp measurement_attributes(%Activity{measurement_type: "rounds_weight"}) do
    %{"rounds" => "18.5", "weight_kg" => "9"}
  end

  defp measurement_attributes(%Activity{measurement_type: "reps"}) do
    %{"repetitions" => "12"}
  end

  defp measurement_attributes(%Activity{measurement_type: "reps_weight"}) do
    %{"repetitions" => "3", "weight_kg" => "70"}
  end

  defp stringify_keys(attrs) do
    Map.new(attrs, fn {key, value} -> {to_string(key), value} end)
  end
end
