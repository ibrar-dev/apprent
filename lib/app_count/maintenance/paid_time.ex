defmodule AppCount.Maintenance.PaidTime do
  use Ecto.Schema
  import Ecto.Changeset

  schema "maintenance__paid_time" do
    field :approved, :boolean, default: false
    field :date, :date
    field :hours, :integer
    field :reason, :string
    belongs_to :tech, Module.concat(["AppCount.Maintenance.Tech"])

    timestamps()
  end

  @doc false
  def changeset(paid_time, attrs) do
    paid_time
    |> cast(attrs, [:hours, :date, :approved, :tech_id, :reason])
    |> validate_required([:hours, :tech_id, :date])
  end
end
