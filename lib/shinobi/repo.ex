defmodule Shinobi.Repo do
  use Ecto.Repo,
    otp_app: :shinobi,
    adapter: Ecto.Adapters.Postgres
end
