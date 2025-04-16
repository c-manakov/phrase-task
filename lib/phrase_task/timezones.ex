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
        where: ilike(t.title, ^"%#{search_string}%"),
        limit: 3
      )
      |> Repo.all()

    # If we have substring matches, return them
    if not Enum.empty?(substring_matches) do
      {:ok, substring_matches}
    else
      # Otherwise, use similarity search
# set word similarity to 0.3 here AI!
      from(t in Timezone,
        where: fragment("? <% ?", ^search_string, t.title),
        order_by: [
          desc: fragment("word_similarity(?, ?)", ^search_string, t.title),
          asc: t.title
        ],
        limit: 3
      )
      |> Repo.all()
      |> then(&{:ok, &1})
    end
  end

  def search_timezones(_), do: {:ok, []}

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
