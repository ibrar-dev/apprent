defmodule BlueMoon.Credentials do
  @enforce_keys [:serial, :user, :password]
  defstruct [:serial, :user, :password, :property_id]

  @type t :: %__MODULE__{}
end
