defmodule PlanningPocker.Model do
  @type role() :: :leader | :patricipant

  defmodule User do
    @type t() :: %__MODULE__{
            name: String.t(),
            role: Model.role()
          }
    defstruct [:name, :role]
  end

  defmodule Room do
    @type t() :: %__MODULE__{
            name: String.t(),
            patricipants: [User.t()]
          }
    defstruct [:name, :patricipants]
  end
end
