defmodule ShinobiWeb.RecordLive.Form do
  use ShinobiWeb, :live_view

  alias Shinobi.Training
  alias Shinobi.Training.Activity
  alias Shinobi.Training.PersonalRecord

  @input_class "min-h-11 w-full rounded-md border border-zinc-300 bg-white px-3 text-base text-zinc-950 outline-none transition placeholder:text-zinc-400 focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-50"
  @textarea_class "min-h-28 w-full rounded-md border border-zinc-300 bg-white px-3 py-2 text-base text-zinc-950 outline-none transition placeholder:text-zinc-400 focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-50"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section id="record-form-page" class="mx-auto max-w-2xl space-y-5">
        <.link
          id="back-to-records"
          navigate={~p"/registros"}
          class="inline-flex items-center gap-2 text-sm font-medium text-zinc-600 transition hover:text-zinc-950 dark:text-zinc-300 dark:hover:text-white"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Historico
        </.link>

        <div>
          <p class="text-xs font-semibold uppercase tracking-widest text-emerald-700 dark:text-emerald-300">
            PR
          </p>
          <h1 class="mt-1 text-3xl font-semibold text-zinc-950 dark:text-zinc-50">
            {@page_title}
          </h1>
          <p class="mt-2 text-sm leading-6 text-zinc-600 dark:text-zinc-300">
            Campos ajustados para {@selected_activity.name}: {Activity.measurement_label(
              @selected_activity.measurement_type
            )}.
          </p>
        </div>

        <.form
          for={@form}
          id="record-form"
          phx-change="validate"
          phx-submit="save"
          class="space-y-4 rounded-lg border border-zinc-200 bg-white p-4 shadow-sm dark:border-zinc-800 dark:bg-zinc-950"
        >
          <.input
            name="personal_record[activity_id]"
            id="personal_record_activity_id"
            type="select"
            label="Atividade"
            options={@activity_options}
            value={@selected_activity.id}
            class={@input_class}
          />

          <.input
            field={@form[:performed_on]}
            type="date"
            label="Data"
            required
            class={@input_class}
          />

          <div
            :if={Activity.time_based?(@selected_activity.measurement_type)}
            id="record-time-fields"
            class="grid grid-cols-2 gap-3"
          >
            <.input
              field={@form[:time_minutes]}
              type="number"
              label="Min"
              min="0"
              inputmode="numeric"
              required
              class={@input_class}
            />
            <.input
              field={@form[:time_seconds]}
              type="number"
              label="Seg"
              min="0"
              max="59"
              inputmode="numeric"
              required
              class={@input_class}
            />
          </div>

          <.input
            :if={Activity.rounds_based?(@selected_activity.measurement_type)}
            field={@form[:rounds]}
            type="number"
            label="Voltas"
            min="0"
            step="0.01"
            inputmode="decimal"
            required
            class={@input_class}
          />

          <.input
            :if={Activity.reps_based?(@selected_activity.measurement_type)}
            field={@form[:repetitions]}
            type="number"
            label="Repeticoes"
            min="0"
            inputmode="numeric"
            required
            class={@input_class}
          />

          <.input
            :if={Activity.weighted?(@selected_activity.measurement_type)}
            field={@form[:weight_kg]}
            type="number"
            label="Carga (kg)"
            min="0"
            step="0.5"
            inputmode="decimal"
            required
            class={@input_class}
          />

          <.input
            field={@form[:notes]}
            type="textarea"
            label="Notas"
            placeholder="Ex.: 1x80kg, 3x70kg, colete 9kg, estrategia ou sensacao."
            class={@textarea_class}
          />

          <button
            id="save-record-button"
            type="submit"
            phx-disable-with="Salvando..."
            class="inline-flex h-12 w-full items-center justify-center gap-2 rounded-lg bg-zinc-950 px-4 text-sm font-semibold text-white shadow-sm transition hover:-translate-y-0.5 hover:bg-zinc-800 active:translate-y-0 dark:bg-emerald-400 dark:text-zinc-950 dark:hover:bg-emerald-300"
          >
            <.icon name="hero-check" class="size-5" /> Salvar PR
          </button>
        </.form>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    activities = Training.list_activities(socket.assigns.current_scope)

    if activities == [] do
      {:ok,
       socket
       |> put_flash(:error, "Cadastre uma atividade antes de registrar PRs.")
       |> push_navigate(to: ~p"/atividades/new")}
    else
      record = load_record(socket.assigns.live_action, socket.assigns.current_scope, params)
      selected_activity = select_activity(activities, params["activity_id"] || record.activity_id)
      record = %{record | activity_id: selected_activity.id, activity: selected_activity}

      socket =
        socket
        |> assign(:page_title, page_title(socket.assigns.live_action))
        |> assign(:activities, activities)
        |> assign(
          :activity_options,
          Enum.map(activities, &{Training.activity_option_label(&1), &1.id})
        )
        |> assign(:input_class, @input_class)
        |> assign(:textarea_class, @textarea_class)
        |> assign(:record, record)
        |> assign_record_form(selected_activity, %{})

      {:ok, socket}
    end
  end

  @impl true
  def handle_event("validate", %{"personal_record" => record_params}, socket) do
    selected_activity = select_activity(socket.assigns.activities, record_params["activity_id"])

    changeset =
      socket.assigns.record
      |> Map.put(:activity_id, selected_activity.id)
      |> Map.put(:activity, selected_activity)
      |> Training.change_personal_record(selected_activity, record_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:selected_activity, selected_activity)
     |> assign(:form, to_form(changeset))}
  end

  def handle_event("save", %{"personal_record" => record_params}, socket) do
    save_record(socket, socket.assigns.live_action, record_params)
  end

  defp load_record(:new, _scope, _params), do: %PersonalRecord{performed_on: Date.utc_today()}

  defp load_record(:edit, scope, %{"id" => id}) do
    Training.get_personal_record!(scope, id)
  end

  defp assign_record_form(socket, selected_activity, attrs) do
    record =
      socket.assigns.record
      |> Map.put(:activity_id, selected_activity.id)
      |> Map.put(:activity, selected_activity)

    socket
    |> assign(:selected_activity, selected_activity)
    |> assign(:record, record)
    |> assign(:form, to_form(Training.change_personal_record(record, selected_activity, attrs)))
  end

  defp save_record(socket, :new, record_params) do
    case Training.create_personal_record(socket.assigns.current_scope, record_params) do
      {:ok, record} ->
        {:noreply,
         socket
         |> put_flash(:info, "PR registrado.")
         |> push_navigate(to: ~p"/registros/#{record}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        selected_activity =
          select_activity(socket.assigns.activities, record_params["activity_id"])

        {:noreply,
         socket
         |> assign(:selected_activity, selected_activity)
         |> assign(:form, to_form(changeset, action: :insert))}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Atividade nao encontrada.")}
    end
  end

  defp save_record(socket, :edit, record_params) do
    case Training.update_personal_record(
           socket.assigns.current_scope,
           socket.assigns.record,
           record_params
         ) do
      {:ok, record} ->
        {:noreply,
         socket
         |> put_flash(:info, "PR atualizado.")
         |> push_navigate(to: ~p"/registros/#{record}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        selected_activity =
          select_activity(socket.assigns.activities, record_params["activity_id"])

        {:noreply,
         socket
         |> assign(:selected_activity, selected_activity)
         |> assign(:form, to_form(changeset, action: :insert))}

      {:error, :not_found} ->
        {:noreply, put_flash(socket, :error, "Atividade nao encontrada.")}
    end
  end

  defp select_activity(activities, activity_id) do
    Enum.find(activities, fn activity -> to_string(activity.id) == to_string(activity_id) end) ||
      List.first(activities)
  end

  defp page_title(:new), do: "Novo PR"
  defp page_title(:edit), do: "Editar PR"
end
