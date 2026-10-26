defmodule ShinobiWeb.PageControllerTest do
  use ShinobiWeb.ConnCase

  test "GET / redirects authenticated users to activities", %{conn: conn} do
    user = Shinobi.AccountsFixtures.user_fixture()

    conn =
      conn
      |> log_in_user(user)
      |> get(~p"/")

    assert redirected_to(conn) == ~p"/atividades"
  end

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
