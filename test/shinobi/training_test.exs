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
