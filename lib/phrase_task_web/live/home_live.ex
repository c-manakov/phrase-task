defmodule PhraseTaskWeb.HomeLive do
  use PhraseTaskWeb, :live_view
  
  @impl true
  def mount(_params, _session, socket) do
    current_time = DateTime.utc_now()
    
    # Sample cities with timezones - in a real app these would come from a database
    cities = [
      %{name: "Hamburg", timezone: "Europe/Berlin"},
      %{name: "Beijing", timezone: "Asia/Shanghai"}
    ]
    
    {:ok, 
     socket
     |> assign(:current_time, current_time)
     |> assign(:use_current_time, true)
     |> assign(:input_time, format_time(current_time))
     |> assign(:cities, cities)
     |> assign(:new_city, "")
     |> schedule_time_update()}
  end
  
  @impl true
  def handle_info(:update_time, socket) do
    current_time = DateTime.utc_now()
    
    socket = 
      if socket.assigns.use_current_time do
        socket
        |> assign(:current_time, current_time)
        |> assign(:input_time, format_time(current_time))
      else
        assign(socket, :current_time, current_time)
      end
    
    {:noreply, schedule_time_update(socket)}
  end
  
  @impl true
  def handle_event("update_time", %{"value" => value}, socket) do
    {:noreply, 
     socket
     |> assign(:input_time, value)
     |> assign(:use_current_time, false)}
  end
  
  @impl true
  def handle_event("use_current_time", _params, socket) do
    current_time = DateTime.utc_now()
    
    {:noreply, 
     socket
     |> assign(:current_time, current_time)
     |> assign(:input_time, format_time(current_time))
     |> assign(:use_current_time, true)}
  end
  
  @impl true
  def handle_event("add_city", %{"city" => city}, socket) when byte_size(city) > 0 do
    # In a real app, we would look up the timezone from a database
    # For this demo, we'll just assign a random timezone
    timezones = ["America/New_York", "Europe/London", "Asia/Tokyo", "Australia/Sydney"]
    timezone = Enum.random(timezones)
    
    new_city = %{name: city, timezone: timezone}
    updated_cities = socket.assigns.cities ++ [new_city]
    
    {:noreply, 
     socket
     |> assign(:cities, updated_cities)
     |> assign(:new_city, "")}
  end
  
  @impl true
  def handle_event("update_new_city", %{"value" => value}, socket) do
    {:noreply, assign(socket, :new_city, value)}
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
    <div>
      <h1 class="text-3xl font-bold text-gray-900 mb-10 text-center">
        Timezone Converter
      </h1>
        
      <div class="bg-white rounded-lg shadow p-6 mb-8">
        <h2 class="text-xl font-medium text-gray-800 mb-4">Enter time</h2>
        <input 
          type="text" 
          value={@input_time} 
          phx-keyup="update_time"
          phx-value-value={@input_time}
          class="w-full border border-gray-300 rounded-md p-3 text-lg mb-2 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition duration-200"
        />
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
                  <div class="col-span-5 font-medium text-gray-900"><%= city.name %></div>
                  <div class="col-span-3 font-mono text-gray-800"><%= convert_time(@current_time, city.timezone) %></div>
                  <div class="col-span-3 text-sm text-gray-500"><%= get_timezone_abbreviation(city.timezone) %></div>
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
          <div class="flex items-end gap-3">
            <div class="flex-1">
              <label for="city-name" class="block mb-2 text-sm font-medium text-gray-700">City name</label>
              <input 
                type="text" 
                id="city-name"
                value={@new_city} 
                phx-keyup="update_new_city"
                phx-value-value={@new_city}
                placeholder="Enter city name..."
                class="w-full border border-gray-300 rounded-md p-3 focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition duration-200"
              />
            </div>
            
            <button 
              phx-click="add_city" 
              phx-value-city={@new_city}
              class="bg-gray-200 hover:bg-gray-300 text-gray-800 font-medium py-3 px-6 rounded-md transition duration-200"
            >
              ADD
            </button>
          </div>
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
  
  defp format_time(datetime) do
    # Format time as HH:MM
    "#{pad_number(datetime.hour)}:#{pad_number(datetime.minute)}"
  end
  
  defp pad_number(number) do
    number |> Integer.to_string() |> String.pad_leading(2, "0")
  end
  
  defp convert_time(datetime, timezone) do
    # In a real app, we would use a proper timezone conversion library
    # For this demo, we'll just add some hours based on the timezone name
    
    # This is a very simplified approach - in a real app use a proper timezone library
    hours_offset = case timezone do
      "Europe/Berlin" -> 2
      "Asia/Shanghai" -> 8
      "America/New_York" -> -4
      "Europe/London" -> 1
      "Asia/Tokyo" -> 9
      "Australia/Sydney" -> 10
      _ -> 0
    end
    
    # Add the offset to the UTC time
    new_hour = rem(datetime.hour + hours_offset + 24, 24)
    "#{pad_number(new_hour)}:#{pad_number(datetime.minute)}"
  end
  
  defp get_timezone_abbreviation(timezone) do
    # This is a simplified approach - in a real app use a proper timezone library
    case timezone do
      "Europe/Berlin" -> "CEST"
      "Asia/Shanghai" -> "CST"
      "America/New_York" -> "EDT"
      "Europe/London" -> "BST"
      "Asia/Tokyo" -> "JST"
      "Australia/Sydney" -> "AEST"
      _ -> "UTC"
    end
  end
end
