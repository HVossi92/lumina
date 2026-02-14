defmodule LuminaWeb.DashboardLive do
  use LuminaWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    orgs = Lumina.Media.Org.for_user!(user.id, actor: user)

    {:ok,
     assign(socket,
       orgs: orgs,
       search_query: "",
       page_title: "Dashboard",
       admin?: user.role == :admin
     )}
  end

  @impl true
  def handle_event("search", %{"q" => q}, socket) do
    {:noreply, assign(socket, search_query: String.trim(q))}
  end

  @impl true
  def render(assigns) do
    q = String.downcase(assigns.search_query || "")

    filtered_orgs =
      if q == "" do
        assigns.orgs
      else
        Enum.filter(assigns.orgs, fn org ->
          String.contains?(String.downcase(org.name || ""), q)
        end)
      end

    assigns = assign(assigns, :filtered_orgs, filtered_orgs)

    ~H"""
    <section>
      <div class="flex flex-wrap items-end justify-between gap-3 mb-8">
        <div>
          <h1 class="text-3xl font-serif font-bold text-base-content text-balance">
            Your Organizations
          </h1>
          <p class="text-sm text-base-content/40 mt-1">
            Manage your photo collections across different organizations.
          </p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <form phx-change="search" class="flex-1 min-w-[200px] max-w-xs">
            <input
              type="search"
              name="q"
              value={@search_query}
              placeholder="Search organizations..."
              phx-debounce="200"
              class="input input-bordered input-sm bg-base-200/60 border-base-300 text-base-content rounded-md w-full"
            />
          </form>
          <%= if @admin? do %>
            <.link
              navigate={~p"/admin/orgs"}
              class="btn btn-sm btn-ghost rounded-md"
            >
              Manage Organizations
            </.link>
            <.link
              navigate={~p"/orgs/new"}
              class="btn btn-sm btn-accent gap-1.5 rounded-md"
            >
              <.icon name="hero-plus" class="size-4" /> Create Organization
            </.link>
          <% else %>
            <.link
              navigate={~p"/join"}
              class="btn btn-sm btn-accent gap-1.5 rounded-md"
            >
              <.icon name="hero-user-plus" class="size-4" /> Join Organization
            </.link>
          <% end %>
        </div>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-5">
        <%= for org <- @filtered_orgs do %>
          <.link
            navigate={~p"/orgs/#{org.slug}"}
            class="group relative flex flex-col rounded-md border border-base-300 bg-base-200 px-6 py-5 hover:border-base-content/20 hover:shadow-md transition"
          >
            <h3 class="text-xl font-serif font-semibold text-base-content">{org.name}</h3>
            <p class="mt-2 text-sm text-base-content/40">
              View albums →
            </p>
          </.link>
        <% end %>
      </div>

      <%= if @filtered_orgs == [] do %>
        <div class="flex flex-col items-center justify-center py-16 text-center">
          <div class="bg-base-300 rounded-full p-4 mb-4">
            <.icon name="hero-building-office-2" class="size-8 text-base-content/30" />
          </div>
          <h3 class="text-lg font-serif font-semibold text-base-content mb-1">
            No organizations
          </h3>
          <p class="text-sm text-base-content/40 mb-4 max-w-xs">
            <%= if @admin? do %>
              Get started by creating a new organization or manage existing ones.
            <% else %>
              Join an existing organization using an invite link or code from your administrator.
            <% end %>
          </p>
          <div class="flex flex-wrap gap-3 justify-center">
            <%= if @admin? do %>
              <.link navigate={~p"/admin/orgs"} class="btn btn-sm btn-ghost rounded-md">
                Manage Organizations
              </.link>
              <.link
                navigate={~p"/orgs/new"}
                class="btn btn-sm btn-accent gap-1.5 rounded-md"
              >
                <.icon name="hero-plus" class="size-4" /> New Organization
              </.link>
            <% else %>
              <.link
                navigate={~p"/join"}
                class="btn btn-sm btn-accent gap-1.5 rounded-md"
              >
                <.icon name="hero-user-plus" class="size-4" /> Join Organization
              </.link>
            <% end %>
          </div>
        </div>
      <% end %>
    </section>
    """
  end
end
