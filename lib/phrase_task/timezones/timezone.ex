defmodule PhraseTask.Timezones.Timezone do
  use Ecto.Schema
  import Ecto.Changeset

  schema "timezones" do
    field :title, :string
    field :timezone_id, :string
    field :pretty_timezone_location, :string
    field :timezone_abbr, :string
    field :utc_to_dst_offset, :integer

    timestamps()
  end

  @doc false
  def changeset(timezone, attrs) do
    timezone
    |> cast(attrs, [:title, :timezone_id, :pretty_timezone_location, :timezone_abbr, :utc_to_dst_offset])
    |> validate_required([:title, :timezone_id])
  end
end
