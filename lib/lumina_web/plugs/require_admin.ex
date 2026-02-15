defmodule LuminaWeb.Plugs.RequireAdmin do
  @moduledoc """
  Ensures the connection has a logged-in user with admin role.
  Use after the :browser pipeline (load_from_session) so current_user is set.

  - No user or not logged in → redirect to sign-in
  - User present but role != :admin → redirect to / with error flash
  """
  import Plug.Conn
  import Phoenix.Controller

  use LuminaWeb, :verified_routes

  def init(opts), do: opts

  def call(conn, _opts) do
    user = conn.assigns[:current_user]

    cond do
      is_nil(user) ->
        conn
        |> redirect(to: ~p"/sign-in")
        |> halt()

      user.role != :admin ->
        conn
        |> put_flash(:error, "Only administrators can access this page")
        |> redirect(to: ~p"/")
        |> halt()

      true ->
        conn
    end
  end
end
