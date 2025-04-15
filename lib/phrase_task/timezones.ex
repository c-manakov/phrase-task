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
    from(t in Timezone,
      where: fragment("levenshtein(?, ?) <= 2", t.title, ^search_string) or
             fragment("levenshtein(?, ?) <= 2", t.pretty_timezone_location, ^search_string),
      order_by: [
        asc: fragment("levenshtein(?, ?)", t.title, ^search_string),
        asc: fragment("levenshtein(?, ?)", t.pretty_timezone_location, ^search_string),
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
