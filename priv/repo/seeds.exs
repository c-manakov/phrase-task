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

# Clear existing timezones
PhraseTask.Repo.delete_all(PhraseTask.Timezones.Timezone)

# Insert all timezones from TzExtra
TzExtra.countries_time_zones()
|> Enum.each(fn timezone ->
  PhraseTask.Repo.insert!(%PhraseTask.Timezones.Timezone{
    title: timezone.name,
    timezone_id: timezone.identifier,
    pretty_timezone_location: "#{timezone.country_name} (#{timezone.country_code})",
    timezone_abbr: timezone.abbreviation,
    utc_to_dst_offset: timezone.utc_offset
  })
end)
