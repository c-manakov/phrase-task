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

PhraseTask.Repo.delete_all(PhraseTask.Timezones.Timezone)

TzExtra.countries_time_zones()
|> Enum.each(fn timezone ->
  PhraseTask.Repo.insert!(%PhraseTask.Timezones.Timezone{
    title: timezone.title,
    timezone_id: timezone.time_zone_id,
    pretty_timezone_location: timezone.pretty_time_zone_location,
    timezone_abbr: timezone.time_zone_abbr,
    utc_to_dst_offset: timezone.utc_to_dst_offset
  })
end)
