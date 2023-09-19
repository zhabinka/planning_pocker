defmodule PlanningPocker.Sessions do
  require Logger

  defmodule Session do
    use GenServer

    defmodule State do
      defstruct [
        :session_id,
        :listening_socket,
        :socket,
        :user
      ]
    end

    def start_link({session_id, listening_socket}) do
      GenServer.start_link(__MODULE__, {session_id, listening_socket})
    end

    @impl true
    def init({session_id, listening_socket}) do
      state = %State{
        session_id: session_id,
        listening_socket: listening_socket
      }

      Logger.info("Sessions has started, state #{inspect(state)}")
      {:ok, state}
    end
  end

  defmodule SessionManager do
    use GenServer

    defmodule State do
      defstruct [
        :port,
        :pool_size,
        :listening_socket
      ]
    end

    def start_link({port, pool_size}) do
      GenServer.start_link(__MODULE__, {port, pool_size})
    end

    @impl true
    def init({port, pool_size}) do
      state = %State{port: port, pool_size: pool_size}
      Logger.info("SessionManager has started, state #{inspect(state)}")
      {:ok, state, {:continue, :delayed_init}}
    end

    @impl true
    def handle_continue(:delayed_init, state) do
      options = [
        :binary,
        {:active, false},
        {:packet, :line},
        {:reuseaddr, true}
      ]

      {:ok, listening_socket} = :gen_tcp.listen(state.port, options)

      1..state.pool_size
      |> Enum.each(fn session_id ->
        PlanningPocker.Sessions.SessionSup.start_acceptor(session_id, listening_socket)
      end)

      state = %State{state | listening_socket: listening_socket}
      {:noreply, state}
    end
  end

  defmodule SessionSup do
    use DynamicSupervisor

    @name :session_sup

    def start_link(_) do
      DynamicSupervisor.start_link(__MODULE__, :no_args, name: @name)
    end

    def start_acceptor(session_id, listening_socket) do
      child_spec = {Session, {session_id, listening_socket}}
      DynamicSupervisor.start_child(@name, child_spec)
    end

    @impl true
    def init(_) do
      Logger.info("SessionSup has started")
      DynamicSupervisor.init(strategy: :one_for_one)
    end
  end
end
