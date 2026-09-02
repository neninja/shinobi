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
    |> activities_query()
    |> maybe_search_activity(opts[:search])
    |> order_by([a], asc: fragment("lower(?)", a.name))
    |> Repo.all()
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

  defp preload_personal_record({:ok, record}), do: {:ok, Repo.preload(record, :activity)}
  defp preload_personal_record(other), do: other
end
