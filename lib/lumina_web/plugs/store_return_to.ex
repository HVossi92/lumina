defmodule LuminaWeb.Plugs.StoreReturnTo do
  @moduledoc """
  Stores return_to from query params in session when redirecting to sign-in.
  Used for join flow: user visits /join/:token unauthenticated, we redirect to
  /sign-in?return_to=/join/:token, and this plug stores it for post-sign-in redirect.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    case conn.params["return_to"] do
      nil ->
        conn

      return_to when is_binary(return_to) and byte_size(return_to) > 0 ->
        put_session(conn, :return_to, return_to)
    end
  end
end
