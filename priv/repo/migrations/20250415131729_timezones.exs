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

    # on the dataset of this size (420) this index doesn't really do anything, the planner just opts for a sequential scan, but in case it would somehow be bigger might as well create it
    execute "create index timezones_title_trgm on timezones using gin (title gin_trgm_ops);"
  end

  def down do
    execute "drop extension pg_trgm;"
    execute "drop index timezones_title_trgm;"

    drop table(:timezones)
  end
end
