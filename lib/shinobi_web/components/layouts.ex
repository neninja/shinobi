defmodule ShinobiWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use ShinobiWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <header class="sticky top-0 z-40 border-b border-zinc-200 bg-white/90 backdrop-blur dark:border-zinc-800 dark:bg-zinc-950/90">
      <div class="mx-auto flex h-16 max-w-5xl items-center justify-between gap-3 px-4 sm:px-6 lg:px-8">
        <.link
          id="app-home-link"
          navigate={if @current_scope && @current_scope.user, do: ~p"/registros", else: ~p"/"}
          class="flex items-center gap-3"
        >
          <span class="inline-flex size-10 items-center justify-center rounded-lg bg-zinc-950 text-sm font-semibold text-white dark:bg-emerald-400 dark:text-zinc-950">
            S
          </span>
          <span class="min-w-0">
            <span class="block text-sm font-semibold leading-5 text-zinc-950 dark:text-zinc-50">
              Shinobi
            </span>
            <span class="block text-xs leading-4 text-zinc-500 dark:text-zinc-400">
              Training log
            </span>
          </span>
        </.link>

        <nav
          :if={@current_scope && @current_scope.user}
          class="hidden items-center gap-1 sm:flex"
          aria-label="Principal"
        >
          <.link
            id="nav-records"
            navigate={~p"/registros"}
            class="rounded-md px-3 py-2 text-sm font-medium text-zinc-600 transition hover:bg-zinc-100 hover:text-zinc-950 dark:text-zinc-300 dark:hover:bg-zinc-800 dark:hover:text-white"
          >
            Historico
          </.link>
          <.link
            id="nav-activities"
            navigate={~p"/atividades"}
            class="rounded-md px-3 py-2 text-sm font-medium text-zinc-600 transition hover:bg-zinc-100 hover:text-zinc-950 dark:text-zinc-300 dark:hover:bg-zinc-800 dark:hover:text-white"
          >
            Atividades
          </.link>
          <.link
            id="nav-settings"
            navigate={~p"/users/settings"}
            class="rounded-md px-3 py-2 text-sm font-medium text-zinc-600 transition hover:bg-zinc-100 hover:text-zinc-950 dark:text-zinc-300 dark:hover:bg-zinc-800 dark:hover:text-white"
          >
            Conta
          </.link>
          <span class="max-w-44 truncate px-2 text-xs font-medium text-zinc-500 dark:text-zinc-400">
            {@current_scope.user.email}
          </span>
          <.link
            id="nav-logout"
            href={~p"/users/log-out"}
            method="delete"
            class="rounded-md px-3 py-2 text-sm font-medium text-red-600 transition hover:bg-red-50 dark:text-red-300 dark:hover:bg-red-950/40"
          >
            Sair
          </.link>
        </nav>

        <nav
          :if={!(@current_scope && @current_scope.user)}
          class="flex items-center gap-2"
          aria-label="Autenticacao"
        >
          <.link
            id="nav-login"
            navigate={~p"/users/log-in"}
            class="rounded-md px-3 py-2 text-sm font-medium text-zinc-600 transition hover:bg-zinc-100 hover:text-zinc-950 dark:text-zinc-300 dark:hover:bg-zinc-800 dark:hover:text-white"
          >
            Entrar
          </.link>
          <.link
            id="nav-register"
            navigate={~p"/users/register"}
            class="rounded-lg bg-zinc-950 px-3 py-2 text-sm font-semibold text-white transition hover:bg-zinc-800 dark:bg-emerald-400 dark:text-zinc-950 dark:hover:bg-emerald-300"
          >
            Criar conta
          </.link>
        </nav>
      </div>
    </header>

    <main class="min-h-[calc(100vh-4rem)] bg-zinc-50 px-4 py-5 pb-24 text-zinc-950 dark:bg-zinc-950 dark:text-zinc-50 sm:px-6 sm:py-8 lg:px-8">
      <div class="mx-auto max-w-5xl">
        {render_slot(@inner_block)}
      </div>
    </main>

    <nav
      :if={@current_scope && @current_scope.user}
      class="fixed inset-x-0 bottom-0 z-40 border-t border-zinc-200 bg-white/95 px-3 pb-[max(0.75rem,env(safe-area-inset-bottom))] pt-2 backdrop-blur dark:border-zinc-800 dark:bg-zinc-950/95 sm:hidden"
      aria-label="Principal mobile"
    >
      <div class="mx-auto grid max-w-md grid-cols-3 gap-2">
        <.link
          id="mobile-nav-records"
          navigate={~p"/registros"}
          class="flex h-12 flex-col items-center justify-center gap-1 rounded-lg text-xs font-medium text-zinc-600 transition hover:bg-zinc-100 hover:text-zinc-950 dark:text-zinc-300 dark:hover:bg-zinc-800 dark:hover:text-white"
        >
          <.icon name="hero-trophy" class="size-5" /> PRs
        </.link>
        <.link
          id="mobile-nav-new-record"
          navigate={~p"/registros/new"}
          class="flex h-12 flex-col items-center justify-center gap-1 rounded-lg bg-zinc-950 text-xs font-semibold text-white shadow-sm transition hover:bg-zinc-800 dark:bg-emerald-400 dark:text-zinc-950 dark:hover:bg-emerald-300"
        >
          <.icon name="hero-plus" class="size-5" /> Novo
        </.link>
        <.link
          id="mobile-nav-activities"
          navigate={~p"/atividades"}
          class="flex h-12 flex-col items-center justify-center gap-1 rounded-lg text-xs font-medium text-zinc-600 transition hover:bg-zinc-100 hover:text-zinc-950 dark:text-zinc-300 dark:hover:bg-zinc-800 dark:hover:text-white"
        >
          <.icon name="hero-list-bullet" class="size-5" /> Atividades
        </.link>
      </div>
    </nav>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>

      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end
end
