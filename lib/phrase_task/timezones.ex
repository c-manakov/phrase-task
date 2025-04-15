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
    # First try to find matches using substring
    substring_matches = 
      from(t in Timezone,
        select: %{timezone: t, similarity: 1.0},
        where: ilike(t.title, ^"%#{search_string}%"),
        order_by: [
          asc: fragment("CASE WHEN ? ILIKE ? THEN 0 ELSE 1 END", t.title, ^"#{search_string}%"),
          asc: t.title
        ],
        limit: 3
      )
      |> Repo.all()

    # If we have substring matches, return them
    if length(substring_matches) > 0 do
      substring_matches
    else
      # Otherwise, use similarity search
      from(t in Timezone,
        select: %{
          timezone: t,
          similarity: fragment("word_similarity(?, ?)", ^search_string, t.title)
        },
        where: fragment("word_similarity(?, ?) > 0.2", ^search_string, t.title),
        order_by: [
          desc: fragment("word_similarity(?, ?)", ^search_string, t.title),
          asc: t.title
        ],
        limit: 3 
      )
      |> Repo.all()
    end
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
