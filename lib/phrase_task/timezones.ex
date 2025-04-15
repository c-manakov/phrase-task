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
    # Use a combination of prefix matching and similarity
    # Prioritize exact prefix matches, then fall back to similarity
    from(t in Timezone,
      where: ilike(t.title, ^"#{search_string}%") or
             (fragment("similarity(?, ?) > 0.6", t.title, ^search_string) and not ilike(t.title, ^"#{search_string}%")),
      order_by: [
        asc: fragment("CASE WHEN ? ILIKE ? THEN 0 ELSE 1 END", t.title, ^"#{search_string}%"),
        asc: fragment("? <-> ?", t.title, ^search_string),
        asc: t.title
      ],
      limit: 10
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
