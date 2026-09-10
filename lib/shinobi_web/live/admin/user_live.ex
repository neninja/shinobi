defmodule ShinobiWeb.Admin.UserLive do
  use Backpex.LiveResource,
    adapter_config: [
      schema: Shinobi.Accounts.User,
      repo: Shinobi.Repo,
      update_changeset: &Shinobi.Accounts.User.admin_changeset/3,
      create_changeset: &Shinobi.Accounts.User.admin_changeset/3
    ],
    init_order: %{by: :inserted_at, direction: :desc},
    fluid?: true

  @impl Backpex.LiveResource
  def singular_name, do: "Usuario"

  @impl Backpex.LiveResource
  def plural_name, do: "Usuarios"

  @impl Backpex.LiveResource
  def layout(_assigns), do: {ShinobiWeb.Layouts, :admin}

  @impl Backpex.LiveResource
  def fields do
    [
      email: %{
        module: Backpex.Fields.Email,
        label: "Email",
        searchable: true,
        orderable: true
      },
      admin: %{
        module: Backpex.Fields.Boolean,
        label: "Admin",
        index_editable: true,
        orderable: true
      },
      confirmed_at: %{
        module: Backpex.Fields.DateTime,
        label: "Confirmado em",
        only: [:index, :show]
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
