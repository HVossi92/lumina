defmodule LuminaWeb.PageController do
  use LuminaWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
