defmodule PlanningPocker.Rooms do
  require Logger

  defmodule Room do
    use GenServer

    def start_link({room_name, process_name}) do
      GenServer.start_link(__MODULE__, room_name, name: process_name)
    end

    @impl true
    def init(room_name) do
      state = %PlanningPocker.Model.Room{
        name: room_name,
        patricipants: []
      }

      Logger.info("#{inspect(state)} has started")
      {:ok, state}
    end
  end
end
