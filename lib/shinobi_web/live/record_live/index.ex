defmodule ShinobiWeb.RecordLive.Index do
  use ShinobiWeb, :live_view

  alias Shinobi.Training
  alias Shinobi.Training.Activity
  alias Shinobi.Training.PersonalRecord

  @select_class "min-h-11 w-full rounded-md border border-zinc-300 bg-white px-3 text-base text-zinc-950 outline-none transition focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-50"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section id="records-page" class="space-y-5">
        <div class="flex items-start justify-between gap-3">
          <div class="min-w-0">
            <p class="text-xs font-semibold uppercase tracking-widest text-emerald-700 dark:text-emerald-300">
              Diario
            </p>
            <h1 class="mt-1 text-3xl font-semibold text-zinc-950 dark:text-zinc-50">
              Historico de PRs
            </h1>
            <p class="mt-2 max-w-2xl text-sm leading-6 text-zinc-600 dark:text-zinc-300">
              Registre resultados rapidamente durante o treino.
            </p>
          </div>

          <.link
            id="new-record-button"
            navigate={~p"/registros/new"}
            class="inline-flex h-11 shrink-0 items-center gap-2 rounded-lg bg-zinc-950 px-4 text-sm font-semibold text-white shadow-sm transition hover:-translate-y-0.5 hover:bg-zinc-800 active:translate-y-0 dark:bg-emerald-400 dark:text-zinc-950 dark:hover:bg-emerald-300"
          >
            <.icon name="hero-plus" class="size-5" /> PR
          </.link>
        </div>

        <.form
          for={@filter_form}
          id="record-filter-form"
          phx-change="filter"
          phx-submit="filter"
          class="rounded-lg border border-zinc-200 bg-white p-3 shadow-sm dark:border-zinc-800 dark:bg-zinc-950"
        >
          <.input
            field={@filter_form[:activity_id]}
            type="select"
            label="Filtrar por atividade"
            options={@filter_activity_options}
            class={@select_class}
          />
        </.form>

        <div id="records" phx-update="stream" class="space-y-3">
          <div
            id="records-empty"
            class="hidden only:block rounded-lg border border-dashed border-zinc-300 bg-white p-6 text-sm text-zinc-500 dark:border-zinc-700 dark:bg-zinc-950 dark:text-zinc-400"
          >
            Nenhum PR registrado ainda.
          </div>

          <article
            :for={{dom_id, record} <- @streams.records}
            id={dom_id}
            class="rounded-lg border border-zinc-200 bg-white p-4 shadow-sm transition hover:-translate-y-0.5 hover:border-emerald-300 hover:shadow-md dark:border-zinc-800 dark:bg-zinc-950 dark:hover:border-emerald-700"
          >
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0">
                <div class="flex flex-wrap items-center gap-2">
                  <p class="text-sm font-medium text-zinc-500 dark:text-zinc-400">
                    {format_date(record.performed_on)}
                  </p>
                  <span class="inline-flex items-center rounded-md bg-zinc-100 px-2 py-1 text-xs font-medium text-zinc-600 ring-1 ring-zinc-200 dark:bg-zinc-800 dark:text-zinc-300 dark:ring-zinc-700">
                    {Activity.measurement_label(record.activity.measurement_type)}
                  </span>
                </div>
                <h2 class="mt-2 truncate text-lg font-semibold text-zinc-950 dark:text-zinc-50">
                  {record.activity.name}
                </h2>
              </div>

              <p class="max-w-[45%] break-words text-right text-2xl font-semibold text-emerald-700 dark:text-emerald-300">
                {PersonalRecord.result_summary(record)}
              </p>
            </div>

            <p
              :if={record.notes not in [nil, ""]}
              class="mt-3 line-clamp-2 text-sm leading-6 text-zinc-600 dark:text-zinc-300"
            >
              {record.notes}
            </p>

            <div class="mt-4 grid grid-cols-3 gap-2">
              <.link
                id={"show-record-#{record.id}"}
                navigate={~p"/registros/#{record}"}
                class="inline-flex h-10 items-center justify-center gap-2 rounded-md border border-zinc-200 text-sm font-medium text-zinc-700 transition hover:bg-zinc-100 dark:border-zinc-700 dark:text-zinc-200 dark:hover:bg-zinc-800"
              >
                <.icon name="hero-eye" class="size-4" /> Ver
              </.link>

              <.link
                id={"edit-record-#{record.id}"}
                navigate={~p"/registros/#{record}/edit"}
                class="inline-flex h-10 items-center justify-center gap-2 rounded-md border border-zinc-200 text-sm font-medium text-zinc-700 transition hover:bg-zinc-100 dark:border-zinc-700 dark:text-zinc-200 dark:hover:bg-zinc-800"
              >
                <.icon name="hero-pencil-square" class="size-4" /> Editar
              </.link>

              <button
                id={"delete-record-#{record.id}"}
                type="button"
                phx-click="delete"
                phx-value-id={record.id}
                data-confirm="Remover este PR?"
                class="inline-flex h-10 items-center justify-center gap-2 rounded-md border border-red-200 text-sm font-medium text-red-600 transition hover:bg-red-50 dark:border-red-900/60 dark:text-red-300 dark:hover:bg-red-950/40"
              >
                <.icon name="hero-trash" class="size-4" /> Excluir
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
    records = Training.list_personal_records(socket.assigns.current_scope)

    socket =
      socket
      |> assign(:page_title, "Historico de PRs")
      |> assign(:select_class, @select_class)
      |> assign_filter(%{})
      |> stream(:records, records)

    {:ok, socket}
  end

  @impl true
  def handle_event("filter", %{"filter" => filter_params}, socket) do
    records = Training.list_personal_records(socket.assigns.current_scope, filter_params)

    socket =
      socket
      |> assign_filter(filter_params)
      |> stream(:records, records, reset: true)

    {:noreply, socket}
  end

  def handle_event("delete", %{"id" => id}, socket) do
    record = Training.get_personal_record!(socket.assigns.current_scope, id)

    {:ok, record} = Training.delete_personal_record(socket.assigns.current_scope, record)

    {:noreply,
     socket
     |> put_flash(:info, "PR removido.")
     |> stream_delete(:records, record)}
  end

  defp assign_filter(socket, params) do
    activity_options =
      [{"Todas as atividades", ""} | Training.list_activity_options(socket.assigns.current_scope)]

    socket
    |> assign(:filter_form, to_form(params, as: :filter))
    |> assign(:filter_activity_options, activity_options)
  end

  defp format_date(date), do: Calendar.strftime(date, "%d/%m/%Y")
end
