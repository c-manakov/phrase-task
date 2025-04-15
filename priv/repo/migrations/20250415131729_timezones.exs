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

    execute "create extension pg_trgm;"
    execute "create index timezones_title_trgm ON timezones USING gin (title gin_trgm_ops);"
  end

  def down do
    execute "drop index timezones_title_trgm;"

    drop table(:timezones)
  end
end
