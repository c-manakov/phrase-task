defmodule PhraseTaskWeb.HomeLiveTest do
  use PhraseTaskWeb.ConnCase

  import Phoenix.LiveViewTest
  alias PhraseTask.Timezones.Timezone
  alias PhraseTask.Repo

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
      |> render_change(%{city_name: "London"})

      view
      |> element("button[phx-click='select_city'][phx-value-index='0']")
      |> render_click()

      html =
        view
        |> element("form[phx-submit='add_city']")
        |> render_submit()
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
