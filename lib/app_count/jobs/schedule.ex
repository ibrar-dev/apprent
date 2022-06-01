defmodule AppCount.Jobs.Schedule do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field :year, {:array, :integer}
    field :month, {:array, :integer}
    field :day, {:array, :integer}
    field :hour, {:array, :integer}, default: [0]
    field :minute, {:array, :integer}, default: [0]
    field :week, {:array, :integer}
    field :wday, {:array, :integer}
  end

  @doc false
  def changeset(job, attrs) do
    job
    |> cast(attrs, [:year, :month, :day, :hour, :minute, :week, :wday])
  end
end
