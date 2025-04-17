defmodule PhraseTask.Timezones do
  @moduledoc """
  The Timezones context.
  """

  import Ecto.Query, warn: false
  alias PhraseTask.Repo
  alias PhraseTask.Timezones.Timezone

  @doc """
  Returns a list of timezones that contain the given search string.

  ## Examples

      iex> search_timezones("New York")
      [%Timezone{}, ...]

  """
  def search_timezones(search_string) when is_binary(search_string) and search_string != "" do
    substring_matches =
      from(t in Timezone,
        where: ilike(t.title, ^"%#{search_string}%"),
        limit: 5
      )
      |> Repo.all()

    # If we have substring matches, return them
    if not Enum.empty?(substring_matches) do
      {:ok, substring_matches}
    else
      # Otherwise, use similarity search
      from(t in Timezone,
        where: fragment("word_similarity(?, ?) > 0.2", ^search_string, t.title),
        order_by: [
          desc: fragment("word_similarity(?, ?)", ^search_string, t.title),
          asc: t.title
        ],
        limit: 5
      )
      |> Repo.all()
      |> then(&{:ok, &1})
    end
  end

  def search_timezones(_), do: {:ok, []}
end
