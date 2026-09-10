defmodule ShinobiWeb.AdminLiveTest do
  use ShinobiWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Shinobi.AccountsFixtures

  test "redirects guests to the login page", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/users/log-in"}}} = live(conn, ~p"/admin/users")
  end

  test "redirects regular users to the app", %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)

    assert {:error, {:redirect, %{to: "/atividades"}}} = live(conn, ~p"/admin/users")
  end

  test "allows admin users to access Backpex resources", %{conn: conn} do
    admin = admin_user_fixture()
    conn = log_in_user(conn, admin)

    {:ok, view, _html} = live(conn, ~p"/admin/users")

    assert has_element?(view, "#backpex-app-shell")
    assert has_element?(view, "#admin-current-user")
    assert has_element?(view, "a[href='/admin/activities']")
  end
end
