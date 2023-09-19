defmodule PlanningPocker do
  use Application
  require Logger

  def start(_start_type, _args) do
    Logger.info("Start PlanningPocker")
    PlanningPocker.RootSup.start_link(:no_args)
  end

  defmodule RootSup do
    use Supervisor

    def start_link(_) do
      Supervisor.start_link(__MODULE__, :no_args)
    end

    @impl true
    def init(_) do
      port = 3000
      pool_size = 5

      child_spec = [
        {PlanningPocker.Rooms.Sup, :no_args},
        {PlanningPocker.Rooms.RoomManager, :no_args},
        {PlanningPocker.Sessions.SessionManager, {port, pool_size}}
      ]

      Supervisor.init(child_spec, strategy: :rest_for_one)
    end
  end
end
