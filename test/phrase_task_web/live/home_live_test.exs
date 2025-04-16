defmodule PhraseTaskWeb.HomeLiveTest do
  use PhraseTaskWeb.ConnCase

  import Phoenix.LiveViewTest
  alias PhraseTask.Timezones.Timezone
  alias PhraseTask.Repo

  use Patch, except: [:patch]

  describe "HomeLive" do
    setup do
      timezones = [
        %{
          title: "America/New_York",
          timezone_id: "America/New_York",
          pretty_timezone_location: "New York",
          timezone_abbr: "EST",
          utc_to_dst_offset: -18000
        },
        %{
          title: "Europe/London",
          timezone_id: "Europe/London",
          pretty_timezone_location: "London",
          timezone_abbr: "GMT",
          utc_to_dst_offset: 0
        },
        %{
          title: "Europe/Kyiv",
          timezone_id: "Europe/Kyiv",
          pretty_timezone_location: "Kyiv",
          timezone_abbr: "EET",
          utc_to_dst_offset: 7200
        },
        %{
          title: "Pacific/Samoa",
          timezone_id: "Pacific/Samoa",
          pretty_timezone_location: "Samoa",
          timezone_abbr: "SST",
          utc_to_dst_offset: -39600
        }
      ]

      Enum.each(timezones, fn timezone_attrs ->
        %Timezone{}
        |> Timezone.changeset(timezone_attrs)
        |> Repo.insert!()
      end)

      :ok
    end

    test "renders the timezone converter page", %{conn: conn} do
      {:ok, view, html} = live(conn, "/")

      assert html =~ "Timezone Converter"
      assert html =~ "Enter time"
      assert html =~ "Your timezones"
    end

    test "allows manual time input", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html =
        view
        |> element("#time-form")
        |> render_change(%{value: "14:30"})

      # Check if time was updated
      assert html =~ "14:30"

      # Check that "Use current time" link is visible
      assert view |> has_element?("a[phx-click='use_current_time']")
    end

    test "can switch back to current time", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("#time-form")
      |> render_change(%{value: "14:30"})
      html =
        view
        |> element("a[phx-click='use_current_time']")
        |> render_click()

      # Time should be in HH:MM format but not 14:30
      assert html =~ ~r/\d{2}:\d{2}/
      refute html =~ "14:30"
    end

    test "shows error for invalid time input", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("#time-form")
      |> render_change(%{value: "invalid"})
      send(view.pid, :check_if_valid)

      # Check if error message is displayed
      assert render(view) =~ "Please enter a valid time"
    end

    test "searches for cities", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html =
        view
        |> element("form[phx-change='update_new_city_search_input']")
        |> render_change(%{city_name: "New York"})
      assert html =~ "America/New_York"
      assert view |> has_element?("#city-results")
    end

    test "selects a city from search results", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("form[phx-change='update_new_city_search_input']")
      |> render_change(%{city_name: "New York"})
      html =
        view
        |> element("button[phx-click='select_city'][phx-value-index='0']")
        |> render_click()

      # Check if city was selected (input should be filled with the city name)
      assert html =~ "America/New_York"
    end

    test "adds a city to the list", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("form[phx-change='update_new_city_search_input']")
      |> render_change(%{city_name: "New York"})

      view
      |> element("button[phx-click='select_city'][phx-value-index='0']")
      |> render_click()
      html =
        view
        |> element("form[phx-submit='add_city']")
        |> render_submit()

      # Check if city was added to the list
      assert html =~ "New York"
      refute html =~ "No cities added yet"
    end

    test "removes a city from the list", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("form[phx-change='update_new_city_search_input']")
      |> render_change(%{city_name: "New York"})

      view
      |> element("button[phx-click='select_city'][phx-value-index='0']")
      |> render_click()

      view
      |> element("form[phx-submit='add_city']")
      |> render_submit()
      assert render(view) =~ "New York"

      html =
        view
        |> element("button[phx-click='remove_city'][phx-value-index='0']")
        |> render_click()
      assert html =~ "No cities added yet"
    end

    test "shows empty search results message", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      html =
        view
        |> element("form[phx-change='update_new_city_search_input']")
        |> render_change(%{city_name: "NonExistentCity"})
      assert html =~ "No matching cities found"
    end

    test "converts time between timezones", %{conn: conn} do
      # Mock Timex.Timezone.local to return a fixed timezone
      Patch.patch(Timex.Timezone, :local, fn -> Timex.Timezone.get("UTC") end)
      
      # Mock a fixed date (January 15, 2023) to avoid DST issues
      fixed_date = ~D[2023-01-15]
      Patch.patch(Timex, :today, fn -> fixed_date end)
      
      {:ok, view, _html} = live(conn, "/")

      view
      |> element("#time-form")
      |> render_change(%{value: "12:00"})

      view
      |> element("form[phx-change='update_new_city_search_input']")
      |> render_change(%{city_name: "New York"})

      view
      |> element("button[phx-click='select_city'][phx-value-index='0']")
      |> render_click()

      view
      |> element("form[phx-submit='add_city']")
      |> render_submit()

      view
      |> element("form[phx-change='update_new_city_search_input']")
      |> render_change(%{city_name: "Kyiv"})

      view
      |> element("button[phx-click='select_city'][phx-value-index='0']")
      |> render_click()

      html =
        view
        |> element("form[phx-submit='add_city']")
        |> render_submit()
        
      assert html =~ "New York"
      assert html =~ "Kyiv"

      {:ok, parsed} = Floki.parse_document(html)
      time_elements = Floki.find(parsed, ".col-span-3.font-mono")
      
      assert Enum.count(time_elements) == 2
      
      times = Enum.map(time_elements, fn element -> 
        Floki.text(element) |> String.trim()
      end)
      
      # In January, New York is on EST (UTC-5) and Kyiv is on EET (UTC+2)
      assert Enum.member?(times, "07:00")
      assert Enum.member?(times, "14:00")

      # Change the time to 18:00 UTC
      view
      |> element("#time-form")
      |> render_change(%{value: "18:00"})

      # Verify the time was updated
      html = render(view)
      assert html =~ "18:00"

      # Add Samoa (UTC-11)
      view
      |> element("form[phx-change='update_new_city_search_input']")
      |> render_change(%{city_name: "Samoa"})

      view
      |> element("button[phx-click='select_city'][phx-value-index='0']")
      |> render_click()

      html =
        view
        |> element("form[phx-submit='add_city']")
        |> render_submit()

      # Verify Samoa was added
      assert html =~ "Samoa"

      # Parse the HTML to check the time values with the new time (18:00 UTC)
      {:ok, parsed} = Floki.parse_document(html)
      time_elements = Floki.find(parsed, ".col-span-3.font-mono")
      
      # We should have 3 time elements now
      assert Enum.count(time_elements) == 3
      
      # Extract the time text from the elements
      times = Enum.map(time_elements, fn element -> 
        Floki.text(element) |> String.trim()
      end)
      
      # With 18:00 UTC:
      # New York should be 13:00 (UTC-5)
      # Kyiv should be 20:00 (UTC+2)
      # Samoa should be 07:00 (UTC-11)
      assert Enum.member?(times, "13:00")
      assert Enum.member?(times, "20:00")
      assert Enum.member?(times, "07:00")

      # Switch back to current time
      view
      |> element("a[phx-click='use_current_time']")
      |> render_click()

      # Verify we're back to current time (the time should be in HH:MM format)
# we can just mock the current time too  AI!
      html = render(view)
      assert html =~ ~r/\d{2}:\d{2}/
      refute html =~ "18:00"

    end
  end
end
