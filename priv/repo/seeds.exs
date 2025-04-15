# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     PhraseTask.Repo.insert!(%PhraseTask.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

TzExtra.countries_time_zones()
|> Enum.map(fn timezone ->
  # now populate the db with the timezones from TzExtra here AI!
  dbg(timezone)
end)
