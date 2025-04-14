defmodule PhraseTask.Repo do
  use Ecto.Repo,
    otp_app: :phrase_task,
    adapter: Ecto.Adapters.Postgres
end
