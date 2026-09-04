defmodule Shinobi.Training do
  @moduledoc """
  The Training context keeps activities and personal record history scoped by user.
  """

  import Ecto.Query, warn: false

  alias Shinobi.Accounts.Scope
  alias Shinobi.Repo
  alias Shinobi.Training.Activity
  alias Shinobi.Training.PersonalRecord

  def list_activities(%Scope{} = scope, opts \\ []) do
    scope
    |> activity_listing_query(opts)
    |> Repo.all()
  end

  def list_activity_summaries(%Scope{} = scope, opts \\ []) do
    activities =
      scope
      |> activity_listing_query(opts)
      |> Repo.all()

    records_by_activity = load_personal_records_for_activities(scope, activities)

    activities
    |> Enum.map(fn activity ->
      records =
        records_by_activity
        |> Map.get(activity.id, [])
        |> sort_personal_records_for_activity(activity)

      best_record = List.first(records)

      %{
        activity: activity,
        best_record: best_record,
        best_metric_value: metric_value(best_record, activity),
        record_label: PersonalRecord.primary_metric_label(activity),
        record_value: record_value(best_record, activity),
        records_count: length(records)
      }
    end)
    |> Enum.sort(&activity_summary_before?/2)
  end

  def list_personal_records_for_activity(%Scope{} = scope, %Activity{} = activity) do
    scope
    |> personal_records_query()
    |> where([r], r.activity_id == ^activity.id)
    |> Repo.all()
    |> Enum.map(&%{&1 | activity: activity})
    |> sort_personal_records_for_activity(activity)
  end

  def list_activity_options(%Scope{} = scope) do
    scope
    |> list_activities()
    |> Enum.map(&{activity_option_label(&1), &1.id})
  end

  def get_activity!(%Scope{} = scope, id) do
    scope
    |> activities_query()
    |> where([a], a.id == ^id)
    |> Repo.one!()
  end

  def fetch_activity(%Scope{} = scope, id) do
    with {id, ""} <- Integer.parse(to_string(id)),
         %Activity{} = activity <-
           scope |> activities_query() |> where([a], a.id == ^id) |> Repo.one() do
      {:ok, activity}
    else
      _ -> {:error, :not_found}
    end
  end

  def change_activity(%Activity{} = activity, attrs \\ %{}) do
    Activity.changeset(activity, attrs)
  end

  def create_activity(%Scope{user: user}, attrs) when not is_nil(user) do
    %Activity{user_id: user.id}
    |> Activity.changeset(attrs)
    |> Repo.insert()
  end

  def update_activity(%Scope{} = scope, %Activity{} = activity, attrs) do
    if owned_activity?(scope, activity) do
      activity
      |> Activity.changeset(attrs)
      |> Repo.update()
    else
      {:error, :forbidden}
    end
  end

  def delete_activity(%Scope{} = scope, %Activity{} = activity) do
    if owned_activity?(scope, activity) do
      Repo.delete(activity)
    else
      {:error, :forbidden}
    end
  end

  def owned_activity?(%Scope{user: %{id: user_id}}, %Activity{user_id: user_id}), do: true
  def owned_activity?(_, _), do: false

  def global_activity?(%Activity{user_id: nil}), do: true
  def global_activity?(_), do: false

  def list_personal_records(%Scope{} = scope, opts \\ []) do
    scope
    |> personal_records_query()
    |> maybe_filter_record_activity(opts[:activity_id])
    |> order_by([r], desc: r.performed_on, desc: r.inserted_at)
    |> preload([:activity])
    |> Repo.all()
  end

  def get_personal_record!(%Scope{} = scope, id) do
    scope
    |> personal_records_query()
    |> where([r], r.id == ^id)
    |> preload([:activity])
    |> Repo.one!()
  end

  def change_personal_record(%PersonalRecord{} = record, %Activity{} = activity, attrs \\ %{}) do
    PersonalRecord.changeset(record, attrs, activity)
  end

  def create_personal_record(%Scope{user: user} = scope, attrs) when not is_nil(user) do
    with {:ok, activity} <- fetch_activity(scope, activity_id_from_attrs(attrs)) do
      %PersonalRecord{user_id: user.id, activity_id: activity.id, activity: activity}
      |> PersonalRecord.changeset(attrs, activity)
      |> Repo.insert()
      |> preload_personal_record()
    end
  end

  def update_personal_record(%Scope{} = scope, %PersonalRecord{} = record, attrs) do
    with {:ok, activity} <-
           fetch_activity(scope, activity_id_from_attrs(attrs, record.activity_id)) do
      record
      |> PersonalRecord.changeset(attrs, activity)
      |> Ecto.Changeset.put_change(:activity_id, activity.id)
      |> Repo.update()
      |> preload_personal_record()
    end
  end

  def delete_personal_record(%Scope{} = scope, %PersonalRecord{} = record) do
    record = get_personal_record!(scope, record.id)
    Repo.delete(record)
  end

  def activity_option_label(%Activity{} = activity) do
    scope_label = if global_activity?(activity), do: "global", else: "minha"
    "#{activity.name} (#{Activity.measurement_label(activity.measurement_type)}, #{scope_label})"
  end

  defp activities_query(%Scope{user: %{id: user_id}}) do
    from a in Activity,
      where: is_nil(a.user_id) or a.user_id == ^user_id
  end

  defp activity_listing_query(%Scope{} = scope, opts) do
    scope
    |> activities_query()
    |> maybe_search_activity(opts[:search])
    |> order_by([a], asc: fragment("lower(?)", a.name))
  end

  defp maybe_search_activity(query, nil), do: query
  defp maybe_search_activity(query, ""), do: query

  defp maybe_search_activity(query, search) do
    search = "%#{search}%"
    where(query, [a], ilike(a.name, ^search) or ilike(a.description, ^search))
  end

  defp personal_records_query(%Scope{user: %{id: user_id}}) do
    from r in PersonalRecord,
      where: r.user_id == ^user_id
  end

  defp maybe_filter_record_activity(query, nil), do: query
  defp maybe_filter_record_activity(query, ""), do: query

  defp maybe_filter_record_activity(query, activity_id) do
    case Integer.parse(to_string(activity_id)) do
      {activity_id, ""} -> where(query, [r], r.activity_id == ^activity_id)
      _ -> query
    end
  end

  defp activity_id_from_attrs(attrs, fallback \\ nil) do
    attrs["activity_id"] || attrs[:activity_id] || fallback
  end

  defp load_personal_records_for_activities(_scope, []), do: %{}

  defp load_personal_records_for_activities(%Scope{} = scope, activities) do
    activity_ids = Enum.map(activities, & &1.id)
    activities_by_id = Map.new(activities, &{&1.id, &1})

    scope
    |> personal_records_query()
    |> where([r], r.activity_id in ^activity_ids)
    |> Repo.all()
    |> Enum.map(fn record ->
      %{record | activity: Map.fetch!(activities_by_id, record.activity_id)}
    end)
    |> Enum.group_by(& &1.activity_id)
  end

  defp activity_summary_before?(left, right) do
    case compare_activity_summaries(left, right) do
      :gt -> true
      :lt -> false
      :eq -> activity_name_key(left.activity) < activity_name_key(right.activity)
    end
  end

  defp compare_activity_summaries(left, right) do
    cond do
      present_record?(left.best_record) and not present_record?(right.best_record) ->
        :gt

      not present_record?(left.best_record) and present_record?(right.best_record) ->
        :lt

      true ->
        compare_metric_values(left.best_metric_value, right.best_metric_value)
    end
  end

  defp present_record?(%PersonalRecord{}), do: true
  defp present_record?(_), do: false

  defp activity_name_key(%Activity{name: name, id: id}) do
    {String.downcase(name || ""), id || 0}
  end

  defp record_value(nil, _activity), do: "Sem PR"

  defp record_value(%PersonalRecord{} = record, %Activity{} = activity) do
    PersonalRecord.primary_result_summary(record, activity)
  end

  defp sort_personal_records_for_activity(records, %Activity{} = activity) do
    Enum.sort(records, &personal_record_before?(&1, &2, activity))
  end

  defp personal_record_before?(left, right, %Activity{} = activity) do
    case compare_personal_records(left, right, activity) do
      :gt -> true
      :lt -> false
      :eq -> (left.id || 0) < (right.id || 0)
    end
  end

  defp compare_personal_records(left, right, %Activity{} = activity) do
    primary_comparison =
      left
      |> metric_value(activity)
      |> compare_metric_values(metric_value(right, activity))

    secondary_comparison =
      left
      |> secondary_metric_value(activity)
      |> compare_metric_values(secondary_metric_value(right, activity))

    date_comparison = compare_dates(left.performed_on, right.performed_on)

    cond do
      primary_comparison != :eq -> primary_comparison
      secondary_comparison != :eq -> secondary_comparison
      date_comparison != :eq -> date_comparison
      true -> compare_datetimes(left.inserted_at, right.inserted_at)
    end
  end

  defp metric_value(nil, _activity), do: nil

  defp metric_value(%PersonalRecord{} = record, %Activity{} = activity) do
    measurement_type = activity.measurement_type

    cond do
      Activity.weighted?(measurement_type) -> decimal_metric_value(record.weight_kg)
      Activity.time_based?(measurement_type) -> decimal_metric_value(record.duration_seconds)
      Activity.reps_based?(measurement_type) -> decimal_metric_value(record.repetitions)
      Activity.rounds_based?(measurement_type) -> decimal_metric_value(record.rounds)
      true -> nil
    end
  end

  defp secondary_metric_value(%PersonalRecord{} = record, %Activity{} = activity) do
    measurement_type = activity.measurement_type

    cond do
      Activity.weighted?(measurement_type) and Activity.time_based?(measurement_type) ->
        decimal_metric_value(record.duration_seconds)

      Activity.weighted?(measurement_type) and Activity.reps_based?(measurement_type) ->
        decimal_metric_value(record.repetitions)

      Activity.weighted?(measurement_type) and Activity.rounds_based?(measurement_type) ->
        decimal_metric_value(record.rounds)

      true ->
        nil
    end
  end

  defp decimal_metric_value(nil), do: nil
  defp decimal_metric_value(%Decimal{} = value), do: value
  defp decimal_metric_value(value) when is_integer(value), do: Decimal.new(value)

  defp compare_metric_values(nil, nil), do: :eq
  defp compare_metric_values(nil, _right), do: :lt
  defp compare_metric_values(_left, nil), do: :gt

  defp compare_metric_values(%Decimal{} = left, %Decimal{} = right),
    do: Decimal.compare(left, right)

  defp compare_dates(nil, nil), do: :eq
  defp compare_dates(nil, _right), do: :lt
  defp compare_dates(_left, nil), do: :gt
  defp compare_dates(%Date{} = left, %Date{} = right), do: Date.compare(left, right)

  defp compare_datetimes(nil, nil), do: :eq
  defp compare_datetimes(nil, _right), do: :lt
  defp compare_datetimes(_left, nil), do: :gt

  defp compare_datetimes(%DateTime{} = left, %DateTime{} = right) do
    DateTime.compare(left, right)
  end

  defp preload_personal_record({:ok, record}), do: {:ok, Repo.preload(record, :activity)}
  defp preload_personal_record(other), do: other
end
