defmodule ShinobiWeb.PageControllerTest do
  use ShinobiWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")

    document =
      conn
      |> html_response(200)
      |> LazyHTML.from_fragment()

    assert LazyHTML.filter(document, "#home-page") != []
    assert LazyHTML.filter(document, "#home-login-link") != []
  end
end
