defmodule PhraseTask.Repo.Migrations.Timezones do
  use Ecto.Migration
  
  def up do
    create table(:timezones) do
      add :title, :string
      add :timezone_id, :string
      add :pretty_timezone_location, :string
      add :timezone_abbr, :string
      add :utc_to_dst_offset, :integer

      timestamps()
    end

    execute "create extension fuzzystrmatch;"
    execute "create extension pg_trgm;"
    execute "create index timezones_title_dm on timezones using gin (daitch_mokotoff(title)) with (fastupdate = off);"
    execute "create index timezones_title_trgm on timezones using gin (title gin_trgm_ops);"
    execute "create index timezones_location_trgm on timezones using gin (pretty_timezone_location gin_trgm_ops);"
  end

  def down do
    execute "drop index timezones_title_dm;"
    execute "drop index timezones_title_trgm;"
    execute "drop index timezones_location_trgm;"

    drop table(:timezones)
  end
end
