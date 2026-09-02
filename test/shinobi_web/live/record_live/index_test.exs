defmodule ShinobiWeb.RecordLive.IndexTest do
  use ShinobiWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Shinobi.TrainingFixtures

  setup :register_and_log_in_user

  test "creates and shows a reps plus weight PR", %{conn: conn, scope: scope} do
    activity = activity_fixture(scope, name: "Bench Press", measurement_type: "reps_weight")

    {:ok, view, _html} = live(conn, ~p"/registros/new?#{[activity_id: activity.id]}")

    assert has_element?(view, "#record-form")
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
    assert_redirect(view, ~p"/registros/#{record}")

    {:ok, show_view, _html} = live(conn, ~p"/registros/#{record}")
    assert has_element?(show_view, "#record-reps-detail")
    assert has_element?(show_view, "#record-weight-detail")
  end

  test "lists and deletes only the user's PR", %{conn: conn, scope: scope} do
    activity = activity_fixture(scope, name: "Bar Muscle Up", measurement_type: "reps")
    record = personal_record_fixture(scope, activity, repetitions: "9")

    {:ok, view, _html} = live(conn, ~p"/registros")

    assert has_element?(view, "#records")
    assert has_element?(view, "#show-record-#{record.id}")

    view
    |> element("#delete-record-#{record.id}")
    |> render_click()

    refute has_element?(view, "#show-record-#{record.id}")
  end
end
