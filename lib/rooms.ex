defmodule PlanningPocker.Rooms do
  require Logger

  defmodule Room do
    use GenServer

    def start_link({room_name, process_name}) do
      GenServer.start_link(__MODULE__, room_name, name: process_name)
    end

    def join(room_pid, user) do
      GenServer.call(room_pid, {:join, user})
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

    @impl true
    def handle_call({:join, user}, _from, state) do
      if user in state.patricipants do
        {:reply, {:error, :already_joined}, state}
      else
        patricipants = [user | state.patricipants]
        state = %PlanningPocker.Model.Room{state | patricipants: patricipants}
        Logger.info("User has joined room #{inspect(state)}")
        {:reply, :ok, state}
      end
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

  defmodule RoomManager do
    use GenServer

    def start_link(_) do
      GenServer.start_link(__MODULE__, :no_args, name: __MODULE__)
    end

    def start_room(room_name) do
      GenServer.call(__MODULE__, {:start_room, room_name})
    end

    def find_room(room_name) do
      case Registry.lookup(:room_registry, room_name) do
        [{pid, _}] -> {:ok, pid}
        [] -> {:error, :not_found}
      end
    end

    @impl true
    def init(_) do
      state = %{
        rooms: []
      }

      Logger.info("RoomManager has started with state #{inspect(state)}")
      {:ok, state}
    end

    @impl true
    def handle_call({:start_room, room_name}, _from, %{rooms: rooms} = state) do
      {:ok, _} = Sup.start_room(room_name)
      state = %{state | rooms: [room_name | rooms]}
      Logger.info("RoomManager has started room #{inspect(room_name)}, state: #{inspect(state)}")
      {:reply, :ok, state}
    end
  end
end
