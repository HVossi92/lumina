defmodule LuminaWeb.Plugs.StoreRequestPath do
  @moduledoc """
  Stores the request path in the session so LiveViews can use it for nav highlighting.
  """
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    put_session(conn, "request_path", conn.request_path)
  end
end
