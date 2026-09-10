defmodule ShinobiWeb.ActivityHistoryChart do
  @moduledoc false

  alias Shinobi.Training.Activity
  alias Shinobi.Training.PersonalRecord

  def line_svg(%Activity{} = activity, records) when is_list(records) do
    points =
      records
      |> Enum.sort_by(&{&1.performed_on, &1.inserted_at, &1.id})
      |> Enum.map(&chart_point(&1, activity))
      |> Enum.reject(&is_nil/1)

    if points == [] do
      nil
    else
      activity
      |> chart(points)
      |> Plotto.to_svg!()
    end
  end

  defp chart(%Activity{} = activity, points) do
    Plotto.LineChart.new!(
      [
        %{
          name: series_name(activity),
          color: "#059669",
          data: points
        }
      ],
      width: 760,
      height: 330,
      stroke_width: 3,
      y_min: 0,
      y_min_soft: true,
      y_guidelines: {:dotted, "#D4D4D8"},
      x_guidelines: false,
      suffix: value_suffix(activity),
      tooltip: & &1.tooltip
    )
  end

  defp chart_point(%PersonalRecord{} = record, %Activity{} = activity) do
    case chart_value(record, activity) do
      nil ->
        nil

      value ->
        %{
          label: format_date(record.performed_on),
          value: value,
          tooltip:
            "#{format_date(record.performed_on)} - #{PersonalRecord.result_summary(record)}"
        }
    end
  end

  defp chart_value(%PersonalRecord{} = record, %Activity{} = activity) do
    measurement_type = activity.measurement_type

    cond do
      Activity.weighted?(measurement_type) -> decimal_to_number(record.weight_kg)
      Activity.time_based?(measurement_type) -> seconds_to_minutes(record.duration_seconds)
      Activity.reps_based?(measurement_type) -> record.repetitions
      Activity.rounds_based?(measurement_type) -> decimal_to_number(record.rounds)
      true -> nil
    end
  end

  defp decimal_to_number(nil), do: nil
  defp decimal_to_number(%Decimal{} = value), do: Decimal.to_float(value)
  defp decimal_to_number(value) when is_integer(value), do: value
  defp decimal_to_number(value) when is_float(value), do: value

  defp seconds_to_minutes(nil), do: nil
  defp seconds_to_minutes(seconds), do: Float.round(seconds / 60, 2)

  defp series_name(%Activity{} = activity) do
    measurement_type = activity.measurement_type

    cond do
      Activity.weighted?(measurement_type) -> "Peso"
      Activity.time_based?(measurement_type) -> "Tempo"
      Activity.reps_based?(measurement_type) -> "Repeticoes"
      Activity.rounds_based?(measurement_type) -> "Voltas"
      true -> "Resultado"
    end
  end

  defp value_suffix(%Activity{} = activity) do
    measurement_type = activity.measurement_type

    cond do
      Activity.weighted?(measurement_type) -> " kg"
      Activity.time_based?(measurement_type) -> " min"
      Activity.reps_based?(measurement_type) -> " reps"
      Activity.rounds_based?(measurement_type) -> " voltas"
      true -> nil
    end
  end

  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%d/%m")
end
