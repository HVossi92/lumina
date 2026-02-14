defmodule LuminaWeb.DashboardLive do
  use LuminaWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user

    orgs = Lumina.Media.Org.for_user!(user.id, actor: user)

    {:ok, assign(socket, orgs: orgs, page_title: "Dashboard")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="sm:flex sm:items-center">
        <div class="sm:flex-auto">
          <h1 class="text-3xl font-bold text-gray-900">Your Organizations</h1>
          <p class="mt-2 text-sm text-gray-700">
            Manage your photo collections across different organizations.
          </p>
        </div>
        <div class="mt-4 sm:ml-16 sm:mt-0 sm:flex-none">
          <.link
            navigate={~p"/orgs/new"}
            class="inline-flex items-center justify-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
          >
            Create Organization
          </.link>
        </div>
      </div>

      <div class="mt-8 grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
        <%= for org <- @orgs do %>
          <.link
            navigate={~p"/orgs/#{org.slug}"}
            class="relative flex flex-col rounded-lg border border-gray-300 bg-white px-6 py-5 shadow-sm hover:border-gray-400 hover:shadow-md transition"
          >
            <h3 class="text-xl font-semibold text-gray-900">{org.name}</h3>
            <p class="mt-2 text-sm text-gray-500">
              View albums →
            </p>
          </.link>
        <% end %>
      </div>

      <%= if @orgs == [] do %>
        <div class="mt-8 text-center">
          <svg
            class="mx-auto h-12 w-12 text-gray-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
            />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-gray-900">No organizations</h3>
          <p class="mt-1 text-sm text-gray-500">Get started by creating a new organization.</p>
          <div class="mt-6">
            <.link
              navigate={~p"/orgs/new"}
              class="inline-flex items-center rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500"
            >
              <svg class="-ml-0.5 mr-1.5 h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
                <path d="M10.75 4.75a.75.75 0 00-1.5 0v4.5h-4.5a.75.75 0 000 1.5h4.5v4.5a.75.75 0 001.5 0v-4.5h4.5a.75.75 0 000-1.5h-4.5v-4.5z" />
              </svg>
              New Organization
            </.link>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
