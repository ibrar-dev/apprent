defmodule AppCount.Jobs.Task do
  use Ecto.Schema
  import Ecto.Changeset

  schema "jobs__tasks" do
    field :arguments, AppCount.Jobs.ArgList
    field :attempt_number, :integer
    field :description, :string
    field :error, :string
    field :logs, {:array, :string}
    field :success, :boolean
    field :start_time, :naive_datetime
    field :end_time, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(instance, attrs) do
    instance
    |> cast(attrs, [
      :description,
      :arguments,
      :error,
      :logs,
      :success,
      :attempt_number,
      :start_time,
      :end_time
    ])
    |> validate_required([:description])
  end
end
