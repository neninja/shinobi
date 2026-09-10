defmodule ShinobiWeb.Admin.PersonalRecordLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Shinobi.Training.PersonalRecord,
      repo: Shinobi.Repo,
      update_changeset: &Shinobi.Training.PersonalRecord.admin_changeset/3,
      create_changeset: &Shinobi.Training.PersonalRecord.admin_changeset/3
    ],
    init_order: %{by: :performed_on, direction: :desc},
    fluid?: true

  @impl Backpex.LiveResource
  def singular_name, do: "Registro"

  @impl Backpex.LiveResource
  def plural_name, do: "Registros"

  @impl Backpex.LiveResource
  def layout(_assigns), do: {ShinobiWeb.Layouts, :admin}

  @impl Backpex.LiveResource
  def fields do
    [
      user: %{
        module: Backpex.Fields.BelongsTo,
        label: "Usuario",
        display_field: :email,
        live_resource: ShinobiWeb.Admin.UserLive,
        searchable: true,
        orderable: true
      },
      activity: %{
        module: Backpex.Fields.BelongsTo,
        label: "Atividade",
        display_field: :name,
        live_resource: ShinobiWeb.Admin.ActivityLive,
        searchable: true,
        orderable: true
      },
      performed_on: %{
        module: Backpex.Fields.Date,
        label: "Data",
        orderable: true
      },
      duration_seconds: %{
        module: Backpex.Fields.Number,
        label: "Segundos",
        orderable: true
      },
      rounds: %{
        module: Backpex.Fields.Number,
        label: "Voltas",
        orderable: true
      },
      repetitions: %{
        module: Backpex.Fields.Number,
        label: "Repeticoes",
        orderable: true
      },
      weight_kg: %{
        module: Backpex.Fields.Number,
        label: "Peso kg",
        orderable: true
      },
      notes: %{
        module: Backpex.Fields.Textarea,
        label: "Notas"
      },
      inserted_at: %{
        module: Backpex.Fields.DateTime,
        label: "Criado em",
        only: [:index, :show],
        orderable: true
      }
    ]
  end

  @impl Backpex.LiveResource
  def can?(assigns, _action, _item), do: admin?(assigns)

  defp admin?(%{current_scope: %{user: %{admin: true}}}), do: true
  defp admin?(_assigns), do: false
end
