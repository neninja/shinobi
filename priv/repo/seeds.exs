# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Shinobi.Repo.insert!(%Shinobi.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Shinobi.Repo
alias Shinobi.Training.Activity

import Ecto.Query

global_activities = [
  %{
    name: "Cindy",
    measurement_type: "rounds_weight",
    description: "AMRAP classico medido por voltas. Use peso quando houver carga extra."
  },
  %{
    name: "Karen",
    measurement_type: "time_weight",
    description: "150 wall balls por tempo, registrando tambem a carga usada."
  },
  %{
    name: "Bar Muscle Up",
    measurement_type: "reps",
    description: "Maximo de repeticoes ou melhor serie de bar muscle ups."
  },
  %{
    name: "Bench Press",
    measurement_type: "reps_weight",
    description: "Repeticoes com carga, por exemplo 1x80kg ou 3x70kg."
  },
  %{
    name: "5K Run",
    measurement_type: "time",
    description: "Tempo total para 5 km."
  },
  %{
    name: "Annie",
    measurement_type: "time",
    description: "50-40-30-20-10 double unders e sit-ups por tempo."
  }
]

Enum.each(global_activities, fn attrs ->
  activity =
    Repo.one(
      from activity in Activity,
        where: activity.name == ^attrs.name and is_nil(activity.user_id)
    )

  case activity do
    nil ->
      %Activity{}
      |> Activity.changeset(attrs)
      |> Repo.insert!()

    activity ->
      activity
      |> Activity.changeset(attrs)
      |> Repo.update!()
  end
end)
