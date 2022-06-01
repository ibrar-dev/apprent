defmodule AppCount.Prospects.Referral do
  use Ecto.Schema
  import Ecto.Changeset

  schema "prospects__referral" do
    field :referrer, :string
    field :ip_address, :string

    timestamps()
  end

  @doc false
  def changeset(referral, attrs) do
    referral
    |> cast(attrs, [:referrer, :ip_address])
    |> validate_required([:referrer, :ip_address])
  end
end
