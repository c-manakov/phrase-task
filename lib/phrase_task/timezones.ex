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
    search_term = "%#{search_string}%"
    
    from(t in Timezone,
      where: ilike(t.title, ^search_term) or
             ilike(t.pretty_timezone_location, ^search_term),
      order_by: t.title
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
