defmodule ShinobiWeb.ActivityLive.Index do
  use ShinobiWeb, :live_view

  alias Shinobi.Training
  alias Shinobi.Training.Activity

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section id="activities-page" class="space-y-5">
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <p class="text-xs font-semibold uppercase tracking-widest text-emerald-700 dark:text-emerald-300">
              Biblioteca
            </p>
            <h1 class="mt-1 text-3xl font-semibold text-zinc-950 dark:text-zinc-50">
              Atividades
            </h1>
            <p class="mt-2 max-w-2xl text-sm leading-6 text-zinc-600 dark:text-zinc-300">
              Use atividades globais do seed ou crie suas proprias variacoes.
            </p>
          </div>

          <.link
            id="new-activity-button"
            navigate={~p"/atividades/new"}
            class="inline-flex h-11 shrink-0 items-center gap-2 rounded-lg bg-zinc-950 px-4 text-sm font-semibold text-white shadow-sm transition hover:-translate-y-0.5 hover:bg-zinc-800 active:translate-y-0 dark:bg-emerald-400 dark:text-zinc-950 dark:hover:bg-emerald-300"
          >
            <.icon name="hero-plus" class="size-5" /> Nova
          </.link>
        </div>

        <.form
          for={@filter_form}
          id="activity-filter-form"
          phx-change="search"
          phx-submit="search"
          class="rounded-lg border border-zinc-200 bg-white p-3 shadow-sm dark:border-zinc-800 dark:bg-zinc-950"
        >
          <.input
            field={@filter_form[:q]}
            type="search"
            label="Buscar atividade"
            placeholder="Cindy, bench, corrida..."
            phx-debounce="300"
            class="min-h-11 w-full rounded-md border border-zinc-300 bg-white px-3 text-base text-zinc-950 outline-none transition placeholder:text-zinc-400 focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-50"
          />
        </.form>

        <div id="activities" phx-update="stream" class="grid gap-3 sm:grid-cols-2">
          <div
            id="activities-empty"
            class="hidden only:flex rounded-lg border border-dashed border-zinc-300 bg-white p-6 text-sm text-zinc-500 dark:border-zinc-700 dark:bg-zinc-950 dark:text-zinc-400"
          >
            Nenhuma atividade encontrada.
          </div>

          <article
            :for={{dom_id, activity} <- @streams.activities}
            id={dom_id}
            class="rounded-lg border border-zinc-200 bg-white p-4 shadow-sm transition hover:-translate-y-0.5 hover:border-emerald-300 hover:shadow-md dark:border-zinc-800 dark:bg-zinc-950 dark:hover:border-emerald-700"
          >
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0">
                <h2 class="truncate text-lg font-semibold text-zinc-950 dark:text-zinc-50">
                  {activity.name}
                </h2>
                <div class="mt-2 flex flex-wrap gap-2">
                  <span class="inline-flex items-center rounded-md bg-emerald-50 px-2 py-1 text-xs font-medium text-emerald-700 ring-1 ring-emerald-600/20 dark:bg-emerald-400/10 dark:text-emerald-200 dark:ring-emerald-300/20">
                    {Activity.measurement_label(activity.measurement_type)}
                  </span>
                  <span class="inline-flex items-center rounded-md bg-zinc-100 px-2 py-1 text-xs font-medium text-zinc-600 ring-1 ring-zinc-200 dark:bg-zinc-800 dark:text-zinc-300 dark:ring-zinc-700">
                    <%= if Training.global_activity?(activity) do %>
                      Global
                    <% else %>
                      Minha
                    <% end %>
                  </span>
                </div>
              </div>

              <.link
                id={"show-activity-#{activity.id}"}
                navigate={~p"/atividades/#{activity}"}
                class="inline-flex size-10 shrink-0 items-center justify-center rounded-md border border-zinc-200 text-zinc-700 transition hover:border-emerald-300 hover:bg-emerald-50 hover:text-emerald-700 dark:border-zinc-700 dark:text-zinc-200 dark:hover:bg-emerald-400/10"
                aria-label="Ver atividade"
              >
                <.icon name="hero-eye" class="size-5" />
              </.link>
            </div>

            <p class="mt-3 line-clamp-3 text-sm leading-6 text-zinc-600 dark:text-zinc-300">
              {activity.description || "Sem descricao."}
            </p>

            <div class="mt-4 flex items-center gap-2">
              <.link
                id={"new-record-for-activity-#{activity.id}"}
                navigate={~p"/registros/new?#{[activity_id: activity.id]}"}
                class="inline-flex flex-1 items-center justify-center gap-2 rounded-md bg-emerald-600 px-3 py-2.5 text-sm font-semibold text-white transition hover:bg-emerald-500"
              >
                <.icon name="hero-trophy" class="size-4" /> Registrar PR
              </.link>

              <.link
                :if={Training.owned_activity?(@current_scope, activity)}
                id={"edit-activity-#{activity.id}"}
                navigate={~p"/atividades/#{activity}/edit"}
                class="inline-flex size-10 items-center justify-center rounded-md border border-zinc-200 text-zinc-700 transition hover:bg-zinc-100 dark:border-zinc-700 dark:text-zinc-200 dark:hover:bg-zinc-800"
                aria-label="Editar atividade"
              >
                <.icon name="hero-pencil-square" class="size-5" />
              </.link>

              <button
                :if={Training.owned_activity?(@current_scope, activity)}
                id={"delete-activity-#{activity.id}"}
                type="button"
                phx-click="delete"
                phx-value-id={activity.id}
                data-confirm="Remover esta atividade e seus PRs?"
                class="inline-flex size-10 items-center justify-center rounded-md border border-red-200 text-red-600 transition hover:bg-red-50 dark:border-red-900/60 dark:text-red-300 dark:hover:bg-red-950/40"
                aria-label="Remover atividade"
              >
                <.icon name="hero-trash" class="size-5" />
              </button>
            </div>
          </article>
        </div>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    search = ""
    activities = Training.list_activities(socket.assigns.current_scope, search: search)

    socket =
      socket
      |> assign(:page_title, "Atividades")
      |> assign(:filter_form, to_form(%{"q" => search}, as: :filter))
      |> stream(:activities, activities)

    {:ok, socket}
  end

  @impl true
  def handle_event("search", %{"filter" => %{"q" => search}}, socket) do
    activities = Training.list_activities(socket.assigns.current_scope, search: search)

    socket =
      socket
      |> assign(:filter_form, to_form(%{"q" => search}, as: :filter))
      |> stream(:activities, activities, reset: true)

    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    activity = Training.get_activity!(socket.assigns.current_scope, id)

    case Training.delete_activity(socket.assigns.current_scope, activity) do
      {:ok, activity} ->
        {:noreply,
         socket
         |> put_flash(:info, "Atividade removida.")
         |> stream_delete(:activities, activity)}

      {:error, :forbidden} ->
        {:noreply, put_flash(socket, :error, "Atividades globais nao podem ser removidas.")}
    end
  end
end
