defmodule LuminaWeb.PageControllerTest do
  use LuminaWeb.ConnCase

  test "GET / redirects to sign-in when not authenticated", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) =~ "/sign-in"
  end
end
