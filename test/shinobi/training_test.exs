defmodule Shinobi.TrainingTest do
  use Shinobi.DataCase, async: true

  import Shinobi.AccountsFixtures
  import Shinobi.TrainingFixtures

  alias Shinobi.Training
  alias Shinobi.Training.PersonalRecord

  describe "activities" do
    test "lists global and own activities only" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      global_activity = global_activity_fixture(name: "Global Cindy")
      own_activity = activity_fixture(scope, name: "My Karen")
      _other_activity = activity_fixture(other_scope, name: "Other Bench")

      activity_ids =
        scope
        |> Training.list_activities()
        |> Enum.map(& &1.id)

      assert global_activity.id in activity_ids
      assert own_activity.id in activity_ids
      refute Enum.any?(Training.list_activities(scope), &(&1.name == "Other Bench"))
    end

    test "lists activity summaries ordered by best primary record" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()

      bench = global_activity_fixture(name: "Bench Press", measurement_type: "reps_weight")
      pull_up = activity_fixture(scope, name: "Pull Up", measurement_type: "reps")
      empty = activity_fixture(scope, name: "No PR Yet", measurement_type: "time")

      personal_record_fixture(scope, bench, repetitions: "8", weight_kg: "70")
      best_bench = personal_record_fixture(scope, bench, repetitions: "3", weight_kg: "100")
      personal_record_fixture(scope, pull_up, repetitions: "12")
      personal_record_fixture(other_scope, bench, repetitions: "1", weight_kg: "140")

      summaries = Training.list_activity_summaries(scope)

      assert Enum.map(summaries, & &1.activity.id) == [bench.id, pull_up.id, empty.id]

      bench_summary = List.first(summaries)
      assert bench_summary.best_record.id == best_bench.id
      assert bench_summary.record_label == "Recorde de peso"
      assert bench_summary.record_value == "100 kg"
      assert bench_summary.records_count == 2
    end

    test "does not allow users to update global activities" do
      scope = user_scope_fixture()
      global_activity = global_activity_fixture()

      assert {:error, :forbidden} =
               Training.update_activity(scope, global_activity, %{name: "Edited"})
    end

    test "allows users to manage their own activities" do
      scope = user_scope_fixture()

      assert {:ok, activity} =
               Training.create_activity(scope, %{
                 name: "Strict Pull Up",
                 measurement_type: "reps",
                 description: "Max reps"
               })

      assert activity.user_id == scope.user.id

      assert {:ok, updated_activity} =
               Training.update_activity(scope, activity, %{name: "Strict Pull-ups"})

      assert updated_activity.name == "Strict Pull-ups"
      assert {:ok, _deleted_activity} = Training.delete_activity(scope, updated_activity)
    end
  end

  describe "personal records" do
    test "creates a time plus weight PR and formats the result" do
      scope = user_scope_fixture()
      activity = global_activity_fixture(name: "Karen", measurement_type: "time_weight")

      assert {:ok, personal_record} =
               Training.create_personal_record(scope, %{
                 "activity_id" => activity.id,
                 "performed_on" => "2026-09-02",
                 "time_minutes" => "7",
                 "time_seconds" => "42",
                 "weight_kg" => "9"
               })

      assert personal_record.user_id == scope.user.id
      assert personal_record.duration_seconds == 462
      assert PersonalRecord.result_summary(personal_record) == "7:42 / 9 kg"
    end

    test "validates fields according to the activity measurement type" do
      scope = user_scope_fixture()
      activity = global_activity_fixture(measurement_type: "reps_weight")

      assert {:error, changeset} =
               Training.create_personal_record(scope, %{
                 "activity_id" => activity.id,
                 "performed_on" => "2026-09-02",
                 "repetitions" => "3"
               })

      assert %{weight_kg: ["can't be blank"]} = errors_on(changeset)
    end

    test "lists only the current user's PRs" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      activity = global_activity_fixture()
      own_record = personal_record_fixture(scope, activity)
      _other_record = personal_record_fixture(other_scope, activity)

      records = Training.list_personal_records(scope)

      assert Enum.map(records, & &1.id) == [own_record.id]
    end

    test "lists an activity history with the largest primary record first" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      activity = global_activity_fixture(name: "Deadlift", measurement_type: "reps_weight")

      light = personal_record_fixture(scope, activity, repetitions: "8", weight_kg: "90")
      heavy = personal_record_fixture(scope, activity, repetitions: "2", weight_kg: "130")
      middle = personal_record_fixture(scope, activity, repetitions: "5", weight_kg: "110")
      personal_record_fixture(other_scope, activity, repetitions: "1", weight_kg: "180")

      records = Training.list_personal_records_for_activity(scope, activity)

      assert Enum.map(records, & &1.id) == [heavy.id, middle.id, light.id]
    end

    test "lists a time activity history with the shortest record first" do
      scope = user_scope_fixture()
      other_scope = user_scope_fixture()
      activity = global_activity_fixture(name: "Run 1K", measurement_type: "time")

      slow = personal_record_fixture(scope, activity, time_minutes: "7", time_seconds: "42")
      fast = personal_record_fixture(scope, activity, time_minutes: "5", time_seconds: "30")
      middle = personal_record_fixture(scope, activity, time_minutes: "6", time_seconds: "15")
      personal_record_fixture(other_scope, activity, time_minutes: "4", time_seconds: "10")

      records = Training.list_personal_records_for_activity(scope, activity)

      assert Enum.map(records, & &1.id) == [fast.id, middle.id, slow.id]
    end

    test "uses the shortest duration as the best record for time activities" do
      scope = user_scope_fixture()
      activity = global_activity_fixture(name: "Sprint", measurement_type: "time")

      slow = personal_record_fixture(scope, activity, time_minutes: "7", time_seconds: "42")
      fast = personal_record_fixture(scope, activity, time_minutes: "5", time_seconds: "30")

      summaries = Training.list_activity_summaries(scope, search: "Sprint")

      assert [%{best_record: best_record, record_value: "5:30", records_count: 2}] = summaries
      assert best_record.id == fast.id
      refute best_record.id == slow.id
    end

    test "updates a PR activity and clears fields that no longer apply" do
      scope = user_scope_fixture()
      reps_activity = global_activity_fixture(measurement_type: "reps_weight")
      time_activity = global_activity_fixture(measurement_type: "time")
      personal_record = personal_record_fixture(scope, reps_activity)

      assert {:ok, updated_record} =
               Training.update_personal_record(scope, personal_record, %{
                 "activity_id" => time_activity.id,
                 "performed_on" => "2026-09-02",
                 "time_minutes" => "5",
                 "time_seconds" => "30"
               })

      assert updated_record.activity_id == time_activity.id
      assert updated_record.duration_seconds == 330
      assert updated_record.repetitions == nil
      assert updated_record.weight_kg == nil
    end
  end
end
