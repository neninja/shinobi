defmodule ShinobiWeb.ActivityLive.Form do
  use ShinobiWeb, :live_view

  alias Shinobi.Training
  alias Shinobi.Training.Activity

  @input_class "min-h-11 w-full rounded-md border border-zinc-300 bg-white px-3 text-base text-zinc-950 outline-none transition placeholder:text-zinc-400 focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-50"
  @textarea_class "min-h-28 w-full rounded-md border border-zinc-300 bg-white px-3 py-2 text-base text-zinc-950 outline-none transition placeholder:text-zinc-400 focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-50"

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <section id="activity-form-page" class="mx-auto max-w-2xl space-y-5">
        <.link
          id="back-to-activities"
          navigate={~p"/atividades"}
          class="inline-flex items-center gap-2 text-sm font-medium text-zinc-600 transition hover:text-zinc-950 dark:text-zinc-300 dark:hover:text-white"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Atividades
        </.link>

        <div>
          <p class="text-xs font-semibold uppercase tracking-widest text-emerald-700 dark:text-emerald-300">
            Cadastro
          </p>
          <h1 class="mt-1 text-3xl font-semibold text-zinc-950 dark:text-zinc-50">
            {@page_title}
          </h1>
          <p class="mt-2 text-sm leading-6 text-zinc-600 dark:text-zinc-300">
            Escolha como essa atividade sera medida antes de registrar PRs.
          </p>
        </div>

        <.form
          for={@form}
          id="activity-form"
          phx-change="validate"
          phx-submit="save"
          class="space-y-4 rounded-lg border border-zinc-200 bg-white p-4 shadow-sm dark:border-zinc-800 dark:bg-zinc-950"
        >
          <.input
            field={@form[:name]}
            type="text"
            label="Nome"
            placeholder="Ex.: Cindy com colete"
            required
            class={@input_class}
          />

          <.input
            field={@form[:measurement_type]}
            type="select"
            label="Medida"
            options={@measurement_options}
            required
            class={@input_class}
          />

          <.input
            field={@form[:description]}
            type="textarea"
            label="Descricao"
            placeholder="Padrao do treino, observacoes ou variacao da atividade."
            class={@textarea_class}
          />

          <button
            id="save-activity-button"
            type="submit"
            phx-disable-with="Salvando..."
            class="inline-flex h-12 w-full items-center justify-center gap-2 rounded-lg bg-zinc-950 px-4 text-sm font-semibold text-white shadow-sm transition hover:-translate-y-0.5 hover:bg-zinc-800 active:translate-y-0 dark:bg-emerald-400 dark:text-zinc-950 dark:hover:bg-emerald-300"
          >
            <.icon name="hero-check" class="size-5" /> Salvar atividade
          </button>
        </.form>
      </section>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    case load_activity(socket.assigns.live_action, socket.assigns.current_scope, params) do
      {:ok, activity} ->
        if socket.assigns.live_action == :edit &&
             !Training.owned_activity?(socket.assigns.current_scope, activity) do
          {:ok,
           socket
           |> put_flash(:error, "Atividades globais nao podem ser editadas.")
           |> push_navigate(to: ~p"/atividades/#{activity}")}
        else
          {:ok, assign_form_state(socket, activity, %{})}
        end
    end
  end

  @impl true
  def handle_event("validate", %{"activity" => activity_params}, socket) do
    changeset =
      socket.assigns.activity
      |> Training.change_activity(activity_params)
      |> Map.put(:action, :validate)

    {:noreply, assign(socket, :form, to_form(changeset))}
  end

  def handle_event("save", %{"activity" => activity_params}, socket) do
    save_activity(socket, socket.assigns.live_action, activity_params)
  end

  defp load_activity(:new, _scope, _params), do: {:ok, %Activity{}}

  defp load_activity(:edit, scope, %{"id" => id}) do
    {:ok, Training.get_activity!(scope, id)}
  end

  defp assign_form_state(socket, activity, attrs) do
    page_title =
      case socket.assigns.live_action do
        :new -> "Nova atividade"
        :edit -> "Editar atividade"
      end

    socket
    |> assign(:page_title, page_title)
    |> assign(:activity, activity)
    |> assign(:measurement_options, Activity.measurement_options())
    |> assign(:input_class, @input_class)
    |> assign(:textarea_class, @textarea_class)
    |> assign(:form, to_form(Training.change_activity(activity, attrs)))
  end

  defp save_activity(socket, :new, activity_params) do
    case Training.create_activity(socket.assigns.current_scope, activity_params) do
      {:ok, activity} ->
        {:noreply,
         socket
         |> put_flash(:info, "Atividade criada.")
         |> push_navigate(to: ~p"/atividades/#{activity}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, action: :insert))}
    end
  end

  defp save_activity(socket, :edit, activity_params) do
    case Training.update_activity(
           socket.assigns.current_scope,
           socket.assigns.activity,
           activity_params
         ) do
      {:ok, activity} ->
        {:noreply,
         socket
         |> put_flash(:info, "Atividade atualizada.")
         |> push_navigate(to: ~p"/atividades/#{activity}")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :form, to_form(changeset, action: :insert))}

      {:error, :forbidden} ->
        {:noreply, put_flash(socket, :error, "Voce so pode editar atividades proprias.")}
    end
  end
end
