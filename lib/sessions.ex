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
      {:ok, state, {:continue, :waiting_for_client}}
    end

    @impl true
    def handle_continue(:waiting_for_client, state) do
      IO.puts("Session #{state.session_id} waiting for client")
      {:ok, socket} = :gen_tcp.accept(state.listening_socket)
      state = %State{state | socket: socket}
      IO.puts("Session #{state.session_id} got client, state #{inspect(state)}")
      {:noreply, state, {:continue, :receive_data}}
    end

    def handle_continue(:receive_data, state) do
      IO.puts("Session #{state.session_id} is waiting for data")

      case :gen_tcp.recv(state.socket, 0, 30_000) do
        {:ok, data} ->
          IO.puts("Session #{state.session_id} got data #{data}")
          response = data |> String.trim_trailing() |> handle_request()
          :gen_tcp.send(state.socket, response <> "\n")
          {:noreply, state, {:continue, :receive_data}}

        {:error, :timeout} ->
          IO.puts("Session #{state.session_id} timeout")
          {:noreply, state, {:continue, :receive_data}}

        {:error, error} ->
          IO.puts("Session #{state.session_id} has got error #{inspect(error)}")
          :gen_tcp.close(state.socket)
          {:noreply, state, {:continue, :waiting_for_client}}
      end
    end

    def handle_request(request) do
      alias PlanningPocker.Protocol

      case Protocol.deserialyze(request) do
        {:error, error} ->
          Protocol.serialyze({:error, error})

        event ->
          Logger.info("Event: #{inspect(event)}")
          Protocol.serialyze(:ok)
      end
    end

    def handle_event({:login, name}, state) do
      alias PlanningPocker.UsersDatabase

      result =
        case UsersDatabase.find_by_name(name) do
          {:ok, user} ->
            Logger.info("Auth user #{inspect(user)}")
            :ok

          {:error, :not_found} ->
            Logger.warning("User #{name} auth error")
            {:error, :invalid_auth}
        end

      {result, state}
    end

    # Catch all
    def handle_event(event) do
      Logger.error("Unknown event #{inspect(event)}")
      {:error, :unknown_event}
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
