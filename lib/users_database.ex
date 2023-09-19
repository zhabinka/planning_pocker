defmodule PlanningPocker.UsersDatabase do
  alias PlanningPocker.Model.User

  def get_users() do
    [
      %User{id: 1, name: "Ivan", role: :patricipant},
      %User{id: 2, name: "Fedor", role: :leader},
      %User{id: 3, name: "Anna", role: :patricipant},
      %User{id: 4, name: "Nina", role: :patricipant},
      %User{id: 5, name: "Nikita", role: :patricipant}
    ]
  end

  def find_by_name(name) do
    get_users()
    |> Enum.filter(fn user -> user.name == name end)
    |> case do
      [user] -> {:ok, user}
      [] -> {:error, :not_found}
    end
  end
end
