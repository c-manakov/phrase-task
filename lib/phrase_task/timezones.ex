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
    # Use Levenshtein distance with a cutoff of 2
    # This finds results where the spelling is within 2 character edits
# forget the levenstein instead write a query like this using similarity:
# SELECT name
# FROM items
# WHERE name ILIKE 'user_input%'
#    OR (similarity(name, 'user_input') > 0.6 AND name NOT ILIKE 'user_input%')
# ORDER BY 
#    CASE WHEN name ILIKE 'user_input%' THEN 0 ELSE 1 END,
#    name <-> 'user_input'
# LIMIT 10;
# AI!
    from(t in Timezone,
      where: fragment("levenshtein(?, ?, 10, 1, 10) <= 10", t.title, ^search_string),
      order_by: [
        asc: fragment("levenshtein(?, ?, 10, 1, 10)", t.title, ^search_string),
        asc: t.title
      ],
      limit: 20
    )
    |> Repo.all()
  end

  def search_timezones(_), do: []

  @doc """
  Returns the list of all timezones.

  ## Examples

      iex> list_timezones()
      [%Timezone{}, ...]

  """
  def list_timezones do
    Repo.all(Timezone)
  end

  @doc """
  Gets a single timezone by ID.

  ## Examples

      iex> get_timezone(123)
      %Timezone{}
      
      iex> get_timezone(456)
      nil

  """
  def get_timezone(id), do: Repo.get(Timezone, id)
end
