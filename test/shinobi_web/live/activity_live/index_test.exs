defmodule ShinobiWeb.ActivityLive.IndexTest do
  use ShinobiWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Shinobi.TrainingFixtures

  alias Shinobi.Repo
  alias Shinobi.Training.Activity

  setup :register_and_log_in_user

  test "lists global activities and creates an owned activity", %{conn: conn, scope: scope} do
    global_activity_fixture(name: "Global Cindy", measurement_type: "rounds_weight")

    {:ok, view, _html} = live(conn, ~p"/atividades")

    assert has_element?(view, "#activities-page")
    assert has_element?(view, "#new-activity-button")
    assert has_element?(view, "#activities div", "Global Cindy")

    {:ok, form_view, _html} =
      view
      |> element("#new-activity-button")
      |> render_click()
      |> follow_redirect(conn, ~p"/atividades/new")

    render_submit(
      form(form_view, "#activity-form",
        activity: %{
          name: "Weighted Cindy",
          measurement_type: "rounds_weight",
          description: "Cindy with vest"
        }
      )
    )

    activity = Repo.get_by!(Activity, name: "Weighted Cindy", user_id: scope.user.id)
    assert_redirect(form_view, ~p"/atividades/#{activity}")
  end

  test "does not show edit controls for global activities", %{conn: conn} do
    activity = global_activity_fixture(name: "Seed Karen", measurement_type: "time_weight")

    {:ok, _view, html} = live(conn, ~p"/atividades/#{activity}")

    refute html =~ "edit-activity-button"
    assert html =~ "new-record-for-activity"
  end
end
