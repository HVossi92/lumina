defmodule LuminaWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use LuminaWeb, :html

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

  attr :current_user, :any, default: nil, doc: "the current user when signed in"

  attr :current_path, :string, default: "/", doc: "current request path for nav highlighting"

  attr :sidebar_orgs_with_albums, :list,
    default: [],
    doc: "list of %{org: org, albums: [album]} for sidebar album links"

  attr :inner_content, :any, default: nil, doc: "inner content when used as LiveView layout"

  slot :inner_block, required: false

  def app(assigns) do
    ~H"""
    <div class="flex min-h-screen bg-base-100">
      <.app_sidebar
        current_user={@current_user}
        current_path={@current_path}
        sidebar_orgs_with_albums={@sidebar_orgs_with_albums}
      />

      <main class="flex-1 min-w-0 lg:ml-0">
        <header class="sticky top-0 z-40 bg-base-100/90 backdrop-blur border-b border-base-300 px-4 sm:px-6 py-3 mt-[52px] lg:mt-0">
          <div class="flex items-center justify-end gap-2">
            <.theme_toggle />
            <%= if @current_user do %>
              <a
                href={~p"/sign-out"}
                class="btn btn-ghost btn-sm gap-2 rounded-md"
                id="sign-out-button"
              >
                <.icon name="hero-arrow-right-on-rectangle" class="size-4" /> Sign out
              </a>
            <% end %>
          </div>
        </header>

        <div class="p-4 sm:p-6 lg:p-8 max-w-6xl mx-auto">
          <%= if assigns[:inner_content] do %>
            {@inner_content}
          <% else %>
            {if @inner_block != [], do: render_slot(@inner_block)}
          <% end %>
        </div>
      </main>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  defp app_sidebar(assigns) do
    ~H"""
    <div id="sidebar-wrapper" class="contents">
      <%!-- Mobile top bar --%>
      <div class="lg:hidden flex items-center justify-between bg-base-200 border-b border-base-300 px-4 py-3 fixed top-0 left-0 right-0 z-50">
        <button
          type="button"
          class="btn btn-ghost btn-sm btn-square"
          phx-click={
            JS.remove_class("hidden", to: "#sidebar-overlay")
            |> JS.add_class("translate-x-0", to: "#sidebar-aside")
          }
          aria-label="Open menu"
        >
          <.icon name="hero-bars-3" class="size-5" />
        </button>
        <.link navigate={~p"/"} class="flex items-center gap-2.5">
          <.icon name="hero-photo" class="size-5 text-accent" />
          <span class="font-serif font-bold text-base-content tracking-tight">Lumina</span>
        </.link>
        <div class="w-10" />
      </div>

      <%!-- Mobile overlay --%>
      <div
        id="sidebar-overlay"
        class="lg:hidden fixed inset-0 bg-base-content/20 z-40 hidden"
        phx-click={
          JS.add_class("hidden", to: "#sidebar-overlay")
          |> JS.remove_class("translate-x-0", to: "#sidebar-aside")
        }
      >
      </div>

      <%!-- Sidebar --%>
      <aside
        id="sidebar-aside"
        class={[
          "fixed top-0 left-0 z-50 h-full w-60 bg-base-200 border-r border-base-300 min-h-screen",
          "flex flex-col transition-transform duration-300 ease-in-out -translate-x-full",
          "lg:translate-x-0 lg:static lg:z-auto lg:min-h-screen"
        ]}
      >
        <div class="flex items-center justify-between px-5 py-5 border-b border-base-300">
          <.link navigate={~p"/"} class="flex items-center gap-2.5">
            <.icon name="hero-photo" class="size-5 text-accent" />
            <span class="font-serif font-bold text-lg text-base-content">Lumina</span>
          </.link>
          <button
            type="button"
            class="btn btn-ghost btn-sm btn-square lg:hidden"
            phx-click={
              JS.add_class("hidden", to: "#sidebar-overlay")
              |> JS.remove_class("translate-x-0", to: "#sidebar-aside")
            }
            aria-label="Close menu"
          >
            <.icon name="hero-x-mark" class="size-4" />
          </button>
        </div>

        <nav class="flex-1 overflow-y-auto py-4 px-3">
          <p class="text-[10px] uppercase tracking-[0.15em] text-base-content/40 font-semibold px-3 mb-2">
            Library
          </p>
          <ul class="menu gap-0.5 p-0">
            <li>
              <.nav_link to={~p"/"} label="Dashboard" current_path={@current_path} icon="hero-home" />
            </li>
            <li>
              <.nav_link
                to={~p"/join"}
                label="Join Organization"
                current_path={@current_path}
                icon="hero-user-plus"
              />
            </li>
          </ul>

          <%= if @sidebar_orgs_with_albums != [] do %>
            <div class="border-t border-base-300 my-3" />
            <p class="text-[10px] uppercase tracking-[0.15em] text-base-content/40 font-semibold px-3 mb-2">
              Albums
            </p>
            <div class="space-y-3">
              <%= for %{org: org, albums: albums} <- @sidebar_orgs_with_albums do %>
                <div>
                  <p
                    class="text-xs text-base-content/50 font-medium px-3 mb-1 truncate"
                    title={org.name}
                  >
                    {org.name}
                  </p>
                  <ul class="menu gap-0.5 p-0">
                    <%= for album <- albums do %>
                      <li>
                        <.nav_link
                          to={~p"/orgs/#{org.slug}/albums/#{album.id}"}
                          label={album.name}
                          current_path={@current_path}
                          icon="hero-folder"
                        />
                      </li>
                    <% end %>
                  </ul>
                </div>
              <% end %>
            </div>
          <% end %>

          <div class="border-t border-base-300 my-3" />

          <p class="text-[10px] uppercase tracking-[0.15em] text-base-content/40 font-semibold px-3 mb-2">
            Manage
          </p>
          <ul class="menu gap-0.5 p-0">
            <%= if @current_user && @current_user.role == :admin do %>
              <li>
                <.nav_link
                  to={~p"/admin/orgs"}
                  label="Organizations"
                  current_path={@current_path}
                  icon="hero-building-office-2"
                />
              </li>
              <li>
                <.nav_link
                  to={~p"/admin/backup"}
                  label="Backup"
                  current_path={@current_path}
                  icon="hero-archive-box"
                />
              </li>
            <% end %>
          </ul>
        </nav>

        <div class="border-t border-base-300 p-4">
          <%= if @current_user do %>
            <div class="flex items-center gap-3">
              <div class="avatar placeholder">
                <div class="flex size-8 items-center justify-center rounded-full bg-accent/20 text-accent">
                  <span class="text-xs font-bold leading-none">
                    {user_initials(@current_user)}
                  </span>
                </div>
              </div>
              <div class="flex-1 min-w-0">
                <p class="text-sm font-medium text-base-content truncate">{@current_user.email}</p>
              </div>
            </div>
          <% end %>
        </div>
      </aside>
    </div>
    """
  end

  attr :to, :string, required: true
  attr :label, :string, required: true
  attr :current_path, :string, required: true
  attr :icon, :string, required: true

  defp nav_link(assigns) do
    active = nav_active?(assigns.current_path, assigns.to)
    assigns = assign(assigns, :active, active)

    ~H"""
    <.link
      navigate={@to}
      class={[
        "flex items-center gap-3 px-3 py-2 rounded-md text-sm transition-colors w-full text-left",
        @active && "bg-accent/15 text-accent font-semibold border-l-2 border-accent -ml-px",
        !@active && "text-base-content/60 hover:bg-base-300/60 hover:text-base-content"
      ]}
    >
      <.icon name={@icon} class="size-4 shrink-0" />
      {@label}
    </.link>
    """
  end

  defp nav_active?(current_path, to) do
    cond do
      to == "/" -> current_path == "/"
      true -> String.starts_with?(current_path, to)
    end
  end

  defp user_initials(user) do
    email = user.email || ""
    parts = String.split(email, "@", parts: 2)
    local = Enum.at(parts, 0) || ""
    letters = String.graphemes(local) |> Enum.take(2) |> Enum.map(&String.upcase/1)
    if letters == [], do: "?", else: Enum.join(letters, "")
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
