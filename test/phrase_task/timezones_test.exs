defmodule PhraseTask.TimezonesTest do
  use PhraseTask.DataCase

  alias PhraseTask.Timezones
  alias PhraseTask.Timezones.Timezone

  describe "search_timezones/1" do
    setup do
      # Create test timezones
      timezones = [
        %{title: "America/New_York", timezone_id: "america_new_york", pretty_timezone_location: "New York", timezone_abbr: "EST", utc_to_dst_offset: -18000},
        %{title: "Europe/London", timezone_id: "europe_london", pretty_timezone_location: "London", timezone_abbr: "GMT", utc_to_dst_offset: 0},
        %{title: "Asia/Tokyo", timezone_id: "asia_tokyo", pretty_timezone_location: "Tokyo", timezone_abbr: "JST", utc_to_dst_offset: 32400},
        %{title: "Australia/Sydney", timezone_id: "australia_sydney", pretty_timezone_location: "Sydney", timezone_abbr: "AEST", utc_to_dst_offset: 36000},
        %{title: "Pacific/Auckland", timezone_id: "pacific_auckland", pretty_timezone_location: "Auckland", timezone_abbr: "NZST", utc_to_dst_offset: 43200}
      ]
      
      Enum.each(timezones, fn timezone_attrs ->
        %Timezone{}
        |> Timezone.changeset(timezone_attrs)
        |> Repo.insert!()
      end)
      
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

    test "handles special characters in search string" do
      # Insert a timezone with special characters
      {:ok, _} = %Timezone{
        title: "Europe/Zürich", 
        timezone_id: "europe_zurich", 
        pretty_timezone_location: "Zürich", 
        timezone_abbr: "CET", 
        utc_to_dst_offset: 3600
      } |> Repo.insert()

      {:ok, results} = Timezones.search_timezones("Zürich")
      
      assert length(results) == 1
      assert Enum.at(results, 0).title == "Europe/Zürich"
    end

    test "returns results in correct order for similarity search" do
      # Insert timezones with similar names
      similar_timezones = [
        %{title: "America/Los_Angeles", timezone_id: "america_los_angeles", pretty_timezone_location: "Los Angeles", timezone_abbr: "PST", utc_to_dst_offset: -28800},
        %{title: "America/Los_Cabos", timezone_id: "america_los_cabos", pretty_timezone_location: "Los Cabos", timezone_abbr: "MST", utc_to_dst_offset: -25200},
        %{title: "America/Las_Vegas", timezone_id: "america_las_vegas", pretty_timezone_location: "Las Vegas", timezone_abbr: "PST", utc_to_dst_offset: -28800}
      ]
      
      Enum.each(similar_timezones, fn timezone_attrs ->
        %Timezone{}
        |> Timezone.changeset(timezone_attrs)
        |> Repo.insert!()
      end)

      # Search for something similar to "Los Angeles" but misspelled
      {:ok, results} = Timezones.search_timezones("Los Angelos")
      
      # Should return Los Angeles as the first result due to highest similarity
      assert length(results) > 0
      assert Enum.at(results, 0).title == "America/Los_Angeles"
    end
  end
end
