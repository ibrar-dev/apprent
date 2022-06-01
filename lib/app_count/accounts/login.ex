defmodule AppCount.Accounts.Login do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts__logins" do
    field :type, :string
    field :login_metadata, :map, default: %{}
    belongs_to :account, AppCount.Accounts.Account

    timestamps()
  end

  @doc false
  def changeset(login, attrs) do
    login
    |> cast(attrs, [:type, :account_id, :login_metadata])
    |> validate_required([:type, :account_id])
  end
end
