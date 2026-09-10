defmodule ShinobiWeb.Admin.ActivityLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Shinobi.Training.Activity,
      repo: Shinobi.Repo,
      update_changeset: &Shinobi.Training.Activity.admin_changeset/3,
      create_changeset: &Shinobi.Training.Activity.admin_changeset/3
    ],
    init_order: %{by: :name, direction: :asc},
    fluid?: true

  alias Shinobi.Training.Activity

  @impl Backpex.LiveResource
  def singular_name, do: "Atividade"

  @impl Backpex.LiveResource
  def plural_name, do: "Atividades"

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
        prompt: "Global",
        searchable: true,
        orderable: true
      },
      name: %{
        module: Backpex.Fields.Text,
        label: "Nome",
        searchable: true,
        orderable: true
      },
      measurement_type: %{
        module: Backpex.Fields.Select,
        label: "Medida",
        options: Activity.measurement_options(),
        orderable: true
      },
      description: %{
        module: Backpex.Fields.Textarea,
        label: "Descricao"
      },
      inserted_at: %{
        module: Backpex.Fields.DateTime,
        label: "Criada em",
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
