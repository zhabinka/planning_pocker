defmodule PlanningPocker do
  use Application
  require Logger

  def start(_start_type, _args) do
    Logger.info("Start PlanningPocker")
    {:ok, self()}
  end
end
