defmodule PhraseTask.TimezonesTest do
  use PhraseTask.DataCase

  alias PhraseTask.Timezones
  alias PhraseTask.Timezones.Timezone

  describe "search_timezones/1" do
    setup do
      # replace this with a list and insert each of them with Enum.each... AI!
      {:ok, _} = %Timezone{title: "America/New_York", timezone_id: "america_new_york", pretty_timezone_location: "New York", timezone_abbr: "EST", utc_to_dst_offset: -18000} |> Repo.insert()
      {:ok, _} = %Timezone{title: "Europe/London", timezone_id: "europe_london", pretty_timezone_location: "London", timezone_abbr: "GMT", utc_to_dst_offset: 0} |> Repo.insert()
      {:ok, _} = %Timezone{title: "Asia/Tokyo", timezone_id: "asia_tokyo", pretty_timezone_location: "Tokyo", timezone_abbr: "JST", utc_to_dst_offset: 32400} |> Repo.insert()
      {:ok, _} = %Timezone{title: "Australia/Sydney", timezone_id: "australia_sydney", pretty_timezone_location: "Sydney", timezone_abbr: "AEST", utc_to_dst_offset: 36000} |> Repo.insert()
      {:ok, _} = %Timezone{title: "Pacific/Auckland", timezone_id: "pacific_auckland", pretty_timezone_location: "Auckland", timezone_abbr: "NZST", utc_to_dst_offset: 43200} |> Repo.insert()
      
      :ok
    end

    test "returns matching timezones when search string is found" do
      {:ok, results} = Timezones.search_timezones("New York")
      
      assert length(results) == 1
      assert Enum.at(results, 0).title == "America/New_York"
    end

    test "returns matching timezones with case insensitivity" do
      {:ok, results} = Timezones.search_timezones("new york")
      
      assert length(results) == 1
      assert Enum.at(results, 0).title == "America/New_York"
    end

    test "returns partial matches" do
      {:ok, results} = Timezones.search_timezones("York")
      
      assert length(results) == 1
      assert Enum.at(results, 0).title == "America/New_York"
    end

    test "returns similar matches when no exact substring match is found" do
      # This should use the similarity search since "Sidney" is misspelled
      {:ok, results} = Timezones.search_timezones("Sidney")
      
      assert length(results) > 0
      # The most similar result should be Sydney
      assert Enum.at(results, 0).title == "Australia/Sydney"
    end

    test "returns empty list for empty search string" do
      {:ok, results} = Timezones.search_timezones("")
      
      assert results == []
    end

    test "returns empty list for nil search string" do
      {:ok, results} = Timezones.search_timezones(nil)
      
      assert results == []
    end

    test "limits results to 5 items" do
      # Insert more than 5 matching timezones
      Enum.each(1..10, fn i ->
        {:ok, _} = %Timezone{
          title: "Test/Timezone#{i}", 
          timezone_id: "test_timezone#{i}", 
          pretty_timezone_location: "Test #{i}", 
          timezone_abbr: "TST", 
          utc_to_dst_offset: 0
        } |> Repo.insert()
      end)

      {:ok, results} = Timezones.search_timezones("Test")
      
      assert length(results) == 5
    end
  end
end
