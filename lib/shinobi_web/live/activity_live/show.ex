defmodule ShinobiWeb.ActivityLive.Show do
  use ShinobiWeb, :live_view

  alias Shinobi.Training
  alias Shinobi.Training.Activity
  alias Shinobi.Training.PersonalRecord

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section id="activity-show-page" class="space-y-5">
        <.link
          id="back-to-activities"
          navigate={~p"/atividades"}
          class="inline-flex items-center gap-2 text-sm font-medium text-zinc-600 transition hover:text-zinc-950 dark:text-zinc-300 dark:hover:text-white"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Atividades
        </.link>

        <div class="rounded-lg border border-zinc-200 bg-white p-5 shadow-sm dark:border-zinc-800 dark:bg-zinc-950">
          <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
            <div class="min-w-0">
              <div class="flex flex-wrap gap-2">
                <span class="inline-flex items-center rounded-md bg-emerald-50 px-2 py-1 text-xs font-medium text-emerald-700 ring-1 ring-emerald-600/20 dark:bg-emerald-400/10 dark:text-emerald-200 dark:ring-emerald-300/20">
                  {Activity.measurement_label(@activity.measurement_type)}
                </span>
                <span class="inline-flex items-center rounded-md bg-zinc-100 px-2 py-1 text-xs font-medium text-zinc-600 ring-1 ring-zinc-200 dark:bg-zinc-800 dark:text-zinc-300 dark:ring-zinc-700">
                  <%= if Training.global_activity?(@activity) do %>
                    Global
                  <% else %>
                    Minha
                  <% end %>
                </span>
              </div>

              <h1 class="mt-3 text-3xl font-semibold text-zinc-950 dark:text-zinc-50">
                {@activity.name}
              </h1>
              <p class="mt-3 text-sm leading-6 text-zinc-600 dark:text-zinc-300">
                {@activity.description || "Sem descricao."}
              </p>
            </div>

            <div class="flex gap-2">
              <.link
                id="new-record-for-activity"
                navigate={~p"/registros/new?#{[activity_id: @activity.id]}"}
                class="inline-flex h-11 flex-1 items-center justify-center gap-2 rounded-lg bg-emerald-600 px-4 text-sm font-semibold text-white transition hover:bg-emerald-500 sm:flex-none"
              >
                <.icon name="hero-trophy" class="size-5" /> PR
              </.link>

              <.link
                :if={Training.owned_activity?(@current_scope, @activity)}
                id="edit-activity-button"
                navigate={~p"/atividades/#{@activity}/edit"}
                class="inline-flex size-11 items-center justify-center rounded-lg border border-zinc-200 text-zinc-700 transition hover:bg-zinc-100 dark:border-zinc-700 dark:text-zinc-200 dark:hover:bg-zinc-800"
                aria-label="Editar atividade"
              >
                <.icon name="hero-pencil-square" class="size-5" />
              </.link>

              <button
                :if={Training.owned_activity?(@current_scope, @activity)}
                id="delete-activity-button"
                type="button"
                phx-click="delete"
                data-confirm="Remover esta atividade e seus PRs?"
                class="inline-flex size-11 items-center justify-center rounded-lg border border-red-200 text-red-600 transition hover:bg-red-50 dark:border-red-900/60 dark:text-red-300 dark:hover:bg-red-950/40"
                aria-label="Remover atividade"
              >
                <.icon name="hero-trash" class="size-5" />
              </button>
            </div>
          </div>
        </div>

        <div class="flex items-center justify-between">
          <div>
            <p class="text-xs font-semibold uppercase tracking-widest text-zinc-500 dark:text-zinc-400">
              Historico
            </p>
            <h2 class="mt-1 text-xl font-semibold text-zinc-950 dark:text-zinc-50">
              PRs desta atividade
            </h2>
          </div>
        </div>

        <div id="activity-records" phx-update="stream" class="space-y-3">
          <div
            id="activity-records-empty"
            class="hidden only:block rounded-lg border border-dashed border-zinc-300 bg-white p-6 text-sm text-zinc-500 dark:border-zinc-700 dark:bg-zinc-950 dark:text-zinc-400"
          >
            Nenhum PR registrado para esta atividade.
          </div>

          <article
            :for={{dom_id, record} <- @streams.activity_records}
            id={dom_id}
            class="rounded-lg border border-zinc-200 bg-white p-4 shadow-sm dark:border-zinc-800 dark:bg-zinc-950"
          >
            <div class="flex items-start justify-between gap-3">
              <div>
                <p class="text-sm font-medium text-zinc-500 dark:text-zinc-400">
                  {format_date(record.performed_on)}
                </p>
                <p class="mt-1 text-2xl font-semibold text-zinc-950 dark:text-zinc-50">
                  {PersonalRecord.result_summary(record)}
                </p>
              </div>

              <.link
                id={"show-record-#{record.id}"}
                navigate={~p"/registros/#{record}"}
                class="inline-flex size-10 shrink-0 items-center justify-center rounded-md border border-zinc-200 text-zinc-700 transition hover:bg-zinc-100 dark:border-zinc-700 dark:text-zinc-200 dark:hover:bg-zinc-800"
                aria-label="Ver PR"
              >
                <.icon name="hero-eye" class="size-5" />
              </.link>
            </div>

            <p
              :if={record.notes not in [nil, ""]}
              class="mt-3 text-sm leading-6 text-zinc-600 dark:text-zinc-300"
            >
              {record.notes}
            </p>
          </article>
        </div>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    activity = Training.get_activity!(socket.assigns.current_scope, id)

    records =
      Training.list_personal_records(socket.assigns.current_scope, activity_id: activity.id)

    socket =
      socket
      |> assign(:page_title, activity.name)
      |> assign(:activity, activity)
      |> stream(:activity_records, records)

    {:ok, socket}
  end

  @impl true
  def handle_event("delete", _params, socket) do
    case Training.delete_activity(socket.assigns.current_scope, socket.assigns.activity) do
      {:ok, _activity} ->
        {:noreply,
         socket
         |> put_flash(:info, "Atividade removida.")
         |> push_navigate(to: ~p"/atividades")}

      {:error, :forbidden} ->
        {:noreply, put_flash(socket, :error, "Atividades globais nao podem ser removidas.")}
    end
  end

  defp format_date(date), do: Calendar.strftime(date, "%d/%m/%Y")
end
