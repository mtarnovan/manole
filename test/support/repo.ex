defmodule Manole.Repo do
  @moduledoc false
  use Ecto.Repo,
    otp_app: :manole,
    adapter: Ecto.Adapters.Postgres
end
