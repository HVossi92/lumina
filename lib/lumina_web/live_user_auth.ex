defmodule LuminaWeb.LiveUserAuth do
  @moduledoc """
  Helpers for authenticating users in LiveViews.
  """

  import Phoenix.Component
  use LuminaWeb, :verified_routes

  alias Lumina.Media.Org

  # This is used for nested liveviews to fetch the current user.
  # To use, place the following at the top of that liveview:
  # on_mount {LuminaWeb.LiveUserAuth, :current_user}
  def on_mount(:current_user, _params, session, socket) do
    {:cont, AshAuthentication.Phoenix.LiveSession.assign_new_resources(socket, session)}
  end

  def on_mount(:live_user_optional, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end

  def on_mount(:live_user_required, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:cont, socket}
    else
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/sign-in")}
    end
  end

  def on_mount(:assign_current_path, _params, session, socket) do
    current_path = session["request_path"] || "/"
    socket = assign(socket, :current_path, current_path)

    socket =
      Phoenix.LiveView.attach_hook(
        socket,
        :assign_current_path_on_params,
        :handle_params,
        &assign_current_path_from_uri/3
      )

    {:cont, socket}
  end

  def on_mount(:assign_sidebar_albums, _params, _session, socket) do
    user = socket.assigns.current_user
    sidebar_orgs_with_albums = load_sidebar_orgs_with_albums(user)
    {:cont, assign(socket, :sidebar_orgs_with_albums, sidebar_orgs_with_albums)}
  end

  def on_mount(:live_no_user, _params, _session, socket) do
    if socket.assigns[:current_user] do
      {:halt, Phoenix.LiveView.redirect(socket, to: ~p"/")}
    else
      {:cont, assign(socket, :current_user, nil)}
    end
  end

  defp load_sidebar_orgs_with_albums(nil), do: []

  defp load_sidebar_orgs_with_albums(user) do
    orgs = Org.for_user!(user.id, actor: user)

    orgs
    |> Enum.map(fn org ->
      org = Ash.load!(org, :albums, actor: user, tenant: org.id)
      %{org: org, albums: org.albums || []}
    end)
    |> Enum.filter(fn %{albums: albums} -> albums != [] end)
  end

  defp assign_current_path_from_uri(_params, uri, socket) do
    path = if is_binary(uri), do: URI.parse(uri).path || "/", else: "/"
    {:cont, assign(socket, :current_path, path)}
  end
end
