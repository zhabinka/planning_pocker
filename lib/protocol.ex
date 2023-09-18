defmodule PlanningPocker.Protocol do
  require Logger

  def deserialyze("login " <> name), do: {:login, name}
  def deserialyze("join " <> room_name), do: {:join, room_name}
  def deserialyze("topic " <> description), do: {:topic, description}

  def deserialyze("vote " <> points) do
    {points, _} = Integer.parse(points)
    {:vote, points}
  end

  def deserialyze("show"), do: :show
  def deserialyze("quit"), do: :quit
  def deserialyze(message), do: Logger.error("Protocol: unknown data #{message}")

  def serialyze({:joined, user, room}),
    do: "#{user.role} #{user.name} hash joined to the room #{room.name}"

  def serialyze({:topic, description}), do: "Topic: #{description}"
  def serialyze({:voted, user}), do: "#{user.name} has voted"
  def serialyze({:show, results}), do: "Vote results: #{inspect(results)}"

  def serialyze({:leaved, user, room}),
    do: "#{user.role} #{user.name} hash leaved from the room #{room.name}"

  def serialyze(:ok), do: "OK"
  def serialyze({:error, error}), do: "ERROR: #{inspect(error)}"
end
