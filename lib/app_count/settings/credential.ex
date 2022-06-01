defmodule AppCount.Settings.Credential do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  embedded_schema do
    field :name, :string
    field :value, AppCount.Crypto.LocalCryptedData
  end

  @doc false
  def changeset(credential_set, attrs) do
    credential_set
    |> cast(attrs, [:name, :value])
    |> validate_required([:name, :value])
  end
end
