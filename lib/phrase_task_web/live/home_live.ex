defmodule PhraseTaskWeb.HomeLive do
  use PhraseTaskWeb, :live_view
  use Timex

  @impl true
  def mount(_params, _session, socket) do
    current_time = Timex.local()

    {:ok,
     socket
     |> assign(:time, current_time)
     |> assign(:use_current_time, true)
     |> assign(:cities, [])
     |> assign(:new_city_search_input, "")
     |> assign(:new_city, nil)
     |> assign(:time_input_valid?, true)
     |> assign(:new_city_search_results, [])
     |> schedule_time_update()}
  end

  @impl true
  def handle_info(:update_time, socket) do
    current_time = Timex.local()

    socket =
      if socket.assigns.use_current_time do
        socket
        |> assign(:time, current_time)
      else
        socket
      end

    {:noreply, schedule_time_update(socket)}
  end

  @impl true
  def handle_info(:check_if_valid, socket) do
    input_value = socket.assigns.time_input

    parse_time(input_value)
    |> case do
      {:ok, _time} ->
        {:noreply, socket |> assign(:time_input_valid?, true)}

      _ ->
        {:noreply, socket |> assign(:time_input_valid?, false)}
    end
  end

  @impl true
  def handle_event("update_time", %{"value" => value}, socket) do
    parse_time(value)
    |> case do
      {:ok, time} ->
        {:noreply,
         socket
         |> assign(:time, time)
         |> assign(:use_current_time, false)
         |> assign(:time_input, value)
         |> assign(:time_input_valid?, true)}

      _otherwise ->
        {:noreply,
         socket
         |> assign(:time_input, value)
         |> schedule_validity_check()}
    end
  end

  @impl true
  def handle_event("use_current_time", _params, socket) do
    current_time = Timex.local()

    {:noreply,
     socket
     |> assign(:time, current_time)
     |> assign(:use_current_time, true)}
  end

  @impl true
  def handle_event("add_city", _, socket) do
    if socket.assigns.new_city do
      new_city = socket.assigns.new_city
      updated_cities = socket.assigns.cities ++ [new_city]

      {:noreply,
       socket
       |> assign(:cities, updated_cities)
       |> assign(:new_city_search_input, "")
       |> assign(:new_city, nil)}
    else
      {:noreply, socket}
    end
  end

  @impl true
  def handle_event("update_new_city_search_input", %{"city_name" => value}, socket) do
    {:ok, results} = PhraseTask.Timezones.search_timezones(value)

    socket =
      socket
      |> assign(:new_city_search_input, value)
      |> assign(:new_city_search_results, results)

    {:noreply, socket}
  end

  @impl true
  def handle_event("select_city", %{"index" => index}, socket) do
    index = String.to_integer(index)
    timezone = Enum.at(socket.assigns.new_city_search_results, index)

    {:noreply,
     socket
     |> assign(:new_city_search_input, timezone.title)
     |> assign(:new_city, timezone)
     |> assign(:new_city_search_results, [])
     |> push_event("focus", %{id: "city-name"})}
  end

  @impl true
  def handle_event("remove_city", %{"index" => index}, socket) do
    index = String.to_integer(index)
    updated_cities = List.delete_at(socket.assigns.cities, index)

    {:noreply, assign(socket, :cities, updated_cities)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div phx-hook="FocusHook" id="focus-hook">
      <h1 class="text-3xl font-bold text-gray-900 mb-10 text-center">
        Timezone Converter
      </h1>

      <div class="bg-white rounded-lg shadow p-6 mb-8">
        <h2 class="text-xl font-medium text-gray-800 mb-4">Enter time</h2>

        <.form for={%{}} phx-change="update_time">
          <input
            type="text"
            name="value"
            value={format_time(@time)}
            class="w-full border border-gray-300 rounded-md p-3 text-lg mb-2 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition duration-200"
          />
        </.form>
        <%= if not @time_input_valid? do %>
          <div class="text-red-500 text-sm mt-1 mb-2 flex items-center">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-5 w-5 mr-1"
              viewBox="0 0 20 20"
              fill="currentColor"
            >
              <path
                fill-rule="evenodd"
                d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z"
                clip-rule="evenodd"
              />
            </svg>
            Please enter a valid time in HH:MM format
          </div>
        <% end %>
        <div>
          <a
            href="#"
            phx-click="use_current_time"
            class="text-blue-600 hover:text-blue-800 text-sm font-medium transition duration-200"
          >
            Use current time
          </a>
        </div>
      </div>

      <div class="bg-white rounded-lg shadow p-6 mb-8">
        <h2 class="text-xl font-medium text-gray-800 mb-4">Your timezones</h2>

        <%= if @cities == [] do %>
          <div class="py-6 text-center text-gray-500 italic">
            No cities added yet. Add your first city below.
          </div>
        <% else %>
          <div class="mb-6">
            <div class="grid grid-cols-12 text-sm font-medium text-gray-500 mb-2 px-2">
              <div class="col-span-5">City</div>
              <div class="col-span-3">Time</div>
              <div class="col-span-3">TZ</div>
              <div class="col-span-1"></div>
            </div>

            <div class="divide-y divide-gray-200">
              <%= for {city, index} <- Enum.with_index(@cities) do %>
                <div class="grid grid-cols-12 py-3 px-2 hover:bg-gray-50 transition duration-150 items-center">
                  <div class="col-span-5 font-medium text-gray-900">
                    {city.pretty_timezone_location}
                  </div>
                  <div class="col-span-3 font-mono text-gray-800">
                    {convert_time(@time, city.timezone_id)}
                  </div>
                  <div class="col-span-3 text-sm text-gray-500">
                    {city.timezone_abbr}
                  </div>
                  <div class="col-span-1 text-right">
                    <button
                      phx-click="remove_city"
                      phx-value-index={index}
                      class="bg-red-100 text-red-600 hover:bg-red-200 transition duration-200 rounded px-2 py-1 text-xs"
                      aria-label="Remove city"
                    >
                      x
                    </button>
                  </div>
                </div>
              <% end %>
            </div>
          </div>
        <% end %>

        <div class="pt-4 border-t border-gray-200">
          <.form
            for={%{}}
            phx-change="update_new_city_search_input"
            phx-submit="add_city"
            class="flex items-end gap-3"
          >
            <div class="flex-1 relative">
              <label for="city-name" class="block mb-2 text-sm font-medium text-gray-700">
                City name
              </label>
              <input
                type="text"
                id="city-name"
                name="city_name"
                value={@new_city_search_input}
                placeholder="Enter city name..."
                class="w-full border border-gray-300 rounded-md p-3 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition duration-200"
                autocomplete="off"
              />
              <div
                :if={@new_city_search_input != "" && @new_city == nil}
                id="city-results"
                class="absolute z-10 mt-1 w-full bg-white shadow-lg max-h-60 rounded-md py-1 text-base overflow-auto focus:outline-none sm:text-sm"
                phx-click-away={JS.hide(to: "#city-results")}
              >
                <div class="city-result-items">
                  <%= if @new_city_search_input != "" && Enum.empty?(@new_city_search_results) do %>
                    <div class="py-2 px-3 text-gray-500 italic">
                      No matching cities found
                    </div>
                  <% else %>
                    <%= for {timezone, index} <- Enum.with_index(@new_city_search_results) do %>
                      <button
                        type="button"
                        class="w-full text-left cursor-pointer select-none relative py-2 pl-3 pr-9 hover:bg-gray-100"
                        phx-click="select_city"
                        phx-value-index={index}
                      >
                        <div class="flex items-center">
                          <span class="font-normal block truncate">{timezone.title}</span>
                        </div>
                      </button>
                    <% end %>
                  <% end %>
                </div>
              </div>
            </div>

            <button
              type="submit"
              class="bg-blue-500 hover:bg-blue-600 text-white font-medium py-3 px-6 rounded-md transition duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
              disabled={is_nil(@new_city)}
            >
              ADD
            </button>
          </.form>
        </div>
      </div>

      <div class="text-center text-gray-500 text-sm">
        All times are updated live when using current time
      </div>
    </div>
    """
  end

  defp schedule_time_update(socket) do
    if connected?(socket) do
      Process.send_after(self(), :update_time, 1000)
    end

    socket
  end

  defp schedule_validity_check(socket) do
    if connected?(socket) do
      Process.send_after(self(), :check_if_valid, 5000)
    end

    socket
  end

  defp format_time(datetime) do
    Timex.format!(datetime, "%H:%M", :strftime)
  end

  # flatten this into a with expression AI!
  defp parse_time(datetime_string) do
    Timex.parse(datetime_string, "{h24}:{m}")
    |> case do
      {:ok, time} ->
        today = Timex.today()
        local_timezone = Timex.Timezone.local()
        
        {:ok, time |> Timex.set(date: today) |> Timex.to_datetime(local_timezone)}

      otherwise ->
        otherwise
    end
  end

  defp convert_time(datetime, timezone) do
    datetime
    |> Timex.to_datetime()
    |> Timex.Timezone.convert(timezone)
    |> format_time()
  end
end
