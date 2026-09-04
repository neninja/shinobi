defmodule ShinobiWeb.RecordLive.Show do
  use ShinobiWeb, :live_view

  alias Shinobi.Training
  alias Shinobi.Training.Activity
  alias Shinobi.Training.PersonalRecord

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section id="record-show-page" class="mx-auto max-w-2xl space-y-5">
        <.link
          id="back-to-activity"
          navigate={~p"/atividades/#{@record.activity}"}
          class="inline-flex items-center gap-2 text-sm font-medium text-zinc-600 transition hover:text-zinc-950 dark:text-zinc-300 dark:hover:text-white"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Atividade
        </.link>

        <article class="rounded-lg border border-zinc-200 bg-white p-5 shadow-sm dark:border-zinc-800 dark:bg-zinc-950">
          <div class="flex flex-wrap items-center gap-2">
            <span class="inline-flex items-center rounded-md bg-emerald-50 px-2 py-1 text-xs font-medium text-emerald-700 ring-1 ring-emerald-600/20 dark:bg-emerald-400/10 dark:text-emerald-200 dark:ring-emerald-300/20">
              {Activity.measurement_label(@record.activity.measurement_type)}
            </span>
            <span class="inline-flex items-center rounded-md bg-zinc-100 px-2 py-1 text-xs font-medium text-zinc-600 ring-1 ring-zinc-200 dark:bg-zinc-800 dark:text-zinc-300 dark:ring-zinc-700">
              {format_date(@record.performed_on)}
            </span>
          </div>

          <h1 class="mt-4 text-3xl font-semibold text-zinc-950 dark:text-zinc-50">
            {@record.activity.name}
          </h1>
          <p class="mt-3 break-words text-4xl font-semibold text-emerald-700 dark:text-emerald-300">
            {PersonalRecord.result_summary(@record)}
          </p>

          <dl class="mt-6 grid grid-cols-2 gap-3">
            <div
              :if={Activity.time_based?(@record.activity.measurement_type)}
              id="record-duration-detail"
              class="rounded-lg border border-zinc-200 p-3 dark:border-zinc-800"
            >
              <dt class="text-xs font-semibold uppercase tracking-widest text-zinc-500 dark:text-zinc-400">
                Tempo
              </dt>
              <dd class="mt-1 text-lg font-semibold text-zinc-950 dark:text-zinc-50">
                {PersonalRecord.format_duration(@record.duration_seconds)}
              </dd>
            </div>

            <div
              :if={Activity.rounds_based?(@record.activity.measurement_type)}
              id="record-rounds-detail"
              class="rounded-lg border border-zinc-200 p-3 dark:border-zinc-800"
            >
              <dt class="text-xs font-semibold uppercase tracking-widest text-zinc-500 dark:text-zinc-400">
                Voltas
              </dt>
              <dd class="mt-1 text-lg font-semibold text-zinc-950 dark:text-zinc-50">
                {PersonalRecord.format_decimal(@record.rounds)}
              </dd>
            </div>

            <div
              :if={Activity.reps_based?(@record.activity.measurement_type)}
              id="record-reps-detail"
              class="rounded-lg border border-zinc-200 p-3 dark:border-zinc-800"
            >
              <dt class="text-xs font-semibold uppercase tracking-widest text-zinc-500 dark:text-zinc-400">
                Reps
              </dt>
              <dd class="mt-1 text-lg font-semibold text-zinc-950 dark:text-zinc-50">
                {@record.repetitions}
              </dd>
            </div>

            <div
              :if={Activity.weighted?(@record.activity.measurement_type)}
              id="record-weight-detail"
              class="rounded-lg border border-zinc-200 p-3 dark:border-zinc-800"
            >
              <dt class="text-xs font-semibold uppercase tracking-widest text-zinc-500 dark:text-zinc-400">
                Carga
              </dt>
              <dd class="mt-1 text-lg font-semibold text-zinc-950 dark:text-zinc-50">
                {PersonalRecord.format_weight(@record.weight_kg)}
              </dd>
            </div>
          </dl>

          <div :if={@record.notes not in [nil, ""]} id="record-notes" class="mt-6">
            <h2 class="text-sm font-semibold text-zinc-950 dark:text-zinc-50">Notas</h2>
            <p class="mt-2 whitespace-pre-line text-sm leading-6 text-zinc-600 dark:text-zinc-300">
              {@record.notes}
            </p>
          </div>

          <div class="mt-6 grid grid-cols-2 gap-2">
            <.link
              id="edit-record-button"
              navigate={~p"/registros/#{@record}/edit"}
              class="inline-flex h-11 items-center justify-center gap-2 rounded-lg border border-zinc-200 text-sm font-semibold text-zinc-700 transition hover:bg-zinc-100 dark:border-zinc-700 dark:text-zinc-200 dark:hover:bg-zinc-800"
            >
              <.icon name="hero-pencil-square" class="size-5" /> Editar
            </.link>

            <button
              id="delete-record-button"
              type="button"
              phx-click="delete"
              data-confirm="Remover este PR?"
              class="inline-flex h-11 items-center justify-center gap-2 rounded-lg border border-red-200 text-sm font-semibold text-red-600 transition hover:bg-red-50 dark:border-red-900/60 dark:text-red-300 dark:hover:bg-red-950/40"
            >
              <.icon name="hero-trash" class="size-5" /> Excluir
            </button>
          </div>
        </article>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    record = Training.get_personal_record!(socket.assigns.current_scope, id)

    {:ok,
     socket
     |> assign(:page_title, record.activity.name)
     |> assign(:record, record)}
  end

  @impl true
  def handle_event("delete", _params, socket) do
    activity = socket.assigns.record.activity

    {:ok, _record} =
      Training.delete_personal_record(socket.assigns.current_scope, socket.assigns.record)

    {:noreply,
     socket
     |> put_flash(:info, "PR removido.")
     |> push_navigate(to: ~p"/atividades/#{activity}")}
  end

  defp format_date(date), do: Calendar.strftime(date, "%d/%m/%Y")
end
