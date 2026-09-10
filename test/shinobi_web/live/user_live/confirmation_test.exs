defmodule ShinobiWeb.UserLive.ConfirmationTest do
  use ShinobiWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  describe "magic link disabled" do
    test "redirects to login page", %{conn: conn} do
      {:ok, _lv, html} =
        live(conn, ~p"/users/log-in/token")
        |> follow_redirect(conn, ~p"/users/log-in")

      assert html =~ "Magic link login is disabled."
    end
  end
end
