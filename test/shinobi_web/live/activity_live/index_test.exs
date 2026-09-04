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

  test "opens activity history ordered by the largest record", %{conn: conn, scope: scope} do
    activity = activity_fixture(scope, name: "Bench Press", measurement_type: "reps_weight")
    light_record = personal_record_fixture(scope, activity, repetitions: "8", weight_kg: "70")
    heavy_record = personal_record_fixture(scope, activity, repetitions: "3", weight_kg: "95")

    {:ok, view, _html} = live(conn, ~p"/atividades")

    assert has_element?(view, "#show-activity-#{activity.id}")
    assert has_element?(view, "#activity-record-label-#{activity.id}", "Recorde de peso")
    assert has_element?(view, "#activity-record-value-#{activity.id}", "95 kg")

    {:ok, show_view, _html} =
      view
      |> element("#show-activity-#{activity.id}")
      |> render_click()
      |> follow_redirect(conn, ~p"/atividades/#{activity}")

    assert has_element?(show_view, "#activity-best-record-value", "95 kg")
    assert has_element?(show_view, "#activity-current-record-#{heavy_record.id}")

    record_link_ids =
      show_view
      |> render()
      |> LazyHTML.from_fragment()
      |> LazyHTML.query("#activity-records article a")
      |> LazyHTML.attribute("id")

    assert Enum.take(record_link_ids, 2) == [
             "show-record-#{heavy_record.id}",
             "show-record-#{light_record.id}"
           ]
  end

  test "does not show edit controls for global activities", %{conn: conn} do
    activity = global_activity_fixture(name: "Seed Karen", measurement_type: "time_weight")

    {:ok, view, _html} = live(conn, ~p"/atividades/#{activity}")

    refute has_element?(view, "#edit-activity-button")
    assert has_element?(view, "#new-record-for-activity")
  end
end
