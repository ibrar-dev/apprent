defmodule AppCount.Settings.MoveOutReason do
  use Ecto.Schema
  import Ecto.Changeset

  schema "settings__move_out_reasons" do
    field :name, :string
    has_many :leases, Module.concat(["AppCount.Leases.Lease"])
    timestamps()
  end

  @doc false
  def changeset(move_out_reason, attrs) do
    move_out_reason
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
