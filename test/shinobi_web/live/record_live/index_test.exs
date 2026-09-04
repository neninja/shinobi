defmodule ShinobiWeb.RecordLive.FlowTest do
  use ShinobiWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Shinobi.TrainingFixtures

  setup :register_and_log_in_user

  test "creates a reps plus weight PR and returns to its activity", %{conn: conn, scope: scope} do
    activity = activity_fixture(scope, name: "Bench Press", measurement_type: "reps_weight")

    {:ok, view, _html} = live(conn, ~p"/registros/new?#{[activity_id: activity.id]}")

    assert has_element?(view, "#record-form")
    assert has_element?(view, "#back-to-activity")
    assert has_element?(view, "#personal_record_repetitions")
    assert has_element?(view, "#personal_record_weight_kg")

    render_submit(
      form(view, "#record-form",
        personal_record: %{
          activity_id: activity.id,
          performed_on: "2026-09-02",
          repetitions: "3",
          weight_kg: "70",
          notes: "Top set"
        }
      )
    )

    [record] = Shinobi.Training.list_personal_records(scope)
    assert_redirect(view, ~p"/atividades/#{activity}")

    {:ok, activity_view, _html} = live(conn, ~p"/atividades/#{activity}")
    assert has_element?(activity_view, "#activity-current-record-#{record.id}")
    assert has_element?(activity_view, "#show-record-#{record.id}")
  end

  test "record detail returns and deletes back to its activity", %{conn: conn, scope: scope} do
    activity = activity_fixture(scope, name: "Bar Muscle Up", measurement_type: "reps")
    record = personal_record_fixture(scope, activity, repetitions: "9")

    {:ok, view, _html} = live(conn, ~p"/registros/#{record}")

    assert has_element?(view, "#back-to-activity")
    assert has_element?(view, "#record-reps-detail")

    {:ok, activity_view, _html} =
      view
      |> element("#back-to-activity")
      |> render_click()
      |> follow_redirect(conn, ~p"/atividades/#{activity}")

    assert has_element?(activity_view, "#show-record-#{record.id}")

    {:ok, detail_view, _html} = live(conn, ~p"/registros/#{record}")

    {:ok, deleted_activity_view, _html} =
      detail_view
      |> element("#delete-record-button")
      |> render_click()
      |> follow_redirect(conn, ~p"/atividades/#{activity}")

    refute has_element?(deleted_activity_view, "#show-record-#{record.id}")
  end
end
