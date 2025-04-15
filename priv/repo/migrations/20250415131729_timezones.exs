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
    execute "create index timezones_title_dm on timezones using gin (daitch_mokotoff(title)) with (fastupdate = off);"
  end

  def down do
    execute "drop index timezones_title_dm;"

    drop table(:timezones)
  end
end
