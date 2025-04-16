defmodule PhraseTaskWeb.HomeLiveTest do
  use PhraseTaskWeb.ConnCase

  import Phoenix.LiveViewTest
  alias PhraseTask.Timezones.Timezone
  alias PhraseTask.Repo

  describe "HomeLive" do
    setup do
      # Create test timezones
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

      # Enter a specific time
# so i think here the change needs to be rendered to the form, not the input as it's the form that has phx-change AI!
      html =
        view
        |> element("#time-input")
        |> render_change(%{value: "14:30"})

      # Check if time was updated
      assert html =~ "14:30"

      # Check that "Use current time" link is visible
      assert view |> has_element?("a[phx-click='use_current_time']")
    end

    test "can switch back to current time", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # First set a manual time
      view
      |> element("#time-input")
      |> render_change(%{value: "14:30"})

      # Then switch back to current time
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

      # Enter an invalid time
      view
      |> element("#time-input")
      |> render_change(%{value: "invalid"})

      # Trigger validity check
      send(view.pid, :check_if_valid)

      # Check if error message is displayed
      assert render(view) =~ "Please enter a valid time"
    end

    test "searches for cities", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Search for New York
      html =
        view
        |> element("form[phx-change='update_new_city_search_input'] input#city-name")
        |> render_change(%{city_name: "New York"})

      # Check if search results are displayed
      assert html =~ "America/New_York"
      assert view |> has_element?("#city-results")
    end

    test "selects a city from search results", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Search for New York
      view
      |> element("form[phx-change='update_new_city_search_input'] input#city-name")
      |> render_change(%{city_name: "New York"})

      # Select the city from search results
      html =
        view
        |> element("button[phx-click='select_city'][phx-value-index='0']")
        |> render_click()

      # Check if city was selected (input should be filled with the city name)
      assert html =~ "America/New_York"
    end

    test "adds a city to the list", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Search for New York
      view
      |> element("form[phx-change='update_new_city_search_input'] input#city-name")
      |> render_change(%{city_name: "New York"})

      # Select the city from search results
      view
      |> element("button[phx-click='select_city'][phx-value-index='0']")
      |> render_click()

      # Add the city
      html =
        view
        |> element("button[type='submit']:not([disabled])")
        |> render_click()

      # Check if city was added to the list
      assert html =~ "New York"
      refute html =~ "No cities added yet"
    end

    test "removes a city from the list", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Add a city
      view
      |> element("form[phx-change='update_new_city_search_input'] input#city-name")
      |> render_change(%{city_name: "New York"})

      view
      |> element("button[phx-click='select_city'][phx-value-index='0']")
      |> render_click()

      view
      |> element("button[type='submit']:not([disabled])")
      |> render_click()

      # Verify city was added
      assert render(view) =~ "New York"

      # Remove the city
      html =
        view
        |> element("button[phx-click='remove_city'][phx-value-index='0']")
        |> render_click()

      # Check if city was removed
      assert html =~ "No cities added yet"
    end

    test "shows empty search results message", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Search for a non-existent city
      html =
        view
        |> element("form[phx-change='update_new_city_search_input'] input#city-name")
        |> render_change(%{city_name: "NonExistentCity"})

      # Check if empty results message is displayed
      assert html =~ "No matching cities found"
    end

    test "converts time between timezones", %{conn: conn} do
      {:ok, view, _html} = live(conn, "/")

      # Set a specific time
      view
      |> element("#time-input")
      |> render_change(%{value: "12:00"})

      # Add New York
      view
      |> element("form[phx-change='update_new_city_search_input'] input#city-name")
      |> render_change(%{city_name: "New York"})

      view
      |> element("button[phx-click='select_city'][phx-value-index='0']")
      |> render_click()

      html =
        view
        |> element("button[type='submit']:not([disabled])")
        |> render_click()

      # Add London
      view
      |> element("form[phx-change='update_new_city_search_input'] input#city-name")
      |> render_change(%{city_name: "London"})

      view
      |> element("button[phx-click='select_city'][phx-value-index='0']")
      |> render_click()

      html =
        view
        |> element("button[type='submit']:not([disabled])")
        |> render_click()

      # Check if both cities are displayed with different times
      assert html =~ "New York"
      assert html =~ "London"

      # The times should be different due to timezone differences
      # This is a bit tricky to test precisely since it depends on the local timezone
      # But we can verify that the grid has multiple time entries
      {:ok, parsed} = Floki.parse_document(html)
      assert Enum.count(Floki.find(parsed, ".col-span-3.font-mono")) >= 2
    end
  end
end
