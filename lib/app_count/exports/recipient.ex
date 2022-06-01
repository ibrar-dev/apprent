defmodule AppCount.Exports.Recipient do
  use Ecto.Schema
  import Ecto.Changeset

  schema "exports__recipients" do
    field :email, :string
    field :name, :string
    belongs_to :admin, Module.concat(["AppCount.Admins.Admin"])

    timestamps()
  end

  @doc false
  def changeset(recipient, attrs) do
    recipient
    |> cast(attrs, [:name, :email, :admin_id])
    |> validate_required([:name, :email, :admin_id])
  end
end
