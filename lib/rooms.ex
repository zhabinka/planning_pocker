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

  defmodule Sup do
    use DynamicSupervisor

    @sup_name :room_sup
    @registry_name :room_registry

    def start_link(_) do
      Registry.start_link(keys: :unique, name: @registry_name)
      DynamicSupervisor.start_link(__MODULE__, :no_args, name: @sup_name)
    end

    def start_room(room_name) do
      process_name = {:via, Registry, {@registry_name, room_name}}
      child_spec = {Room, {room_name, process_name}}
      DynamicSupervisor.start_child(@sup_name, child_spec)
    end

    @impl true
    def init(_) do
      Logger.info("#{@sup_name} has started from #{inspect(self())}")
      DynamicSupervisor.init(strategy: :one_for_one)
    end
  end
end
