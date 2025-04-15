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
    # First try exact matching with ILIKE
    exact_matches =
      from(t in Timezone,
        where:
          ilike(t.title, ^"%#{search_string}%") or
            ilike(t.pretty_timezone_location, ^"%#{search_string}%"),
        order_by: t.title
      )
      |> Repo.all()

    # If we have exact matches, return them
    if length(exact_matches) > 0 do
      exact_matches
    else
      # Use PostgreSQL's trigram similarity operator (%) for fuzzy matching
      from(t in Timezone,
        # where:
        #   fragment("? % ?", t.title, ^search_string) or
        #     fragment("? % ?", t.pretty_timezone_location, ^search_string),
        order_by: [
          desc: fragment("similarity(?, ?)", t.title, ^search_string),
          desc: fragment("similarity(?, ?)", t.pretty_timezone_location, ^search_string),
          asc: t.title
        ],
        limit: 10
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
