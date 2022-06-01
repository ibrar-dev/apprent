defmodule AppCount.Accounts.PasswordReset do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts__password_resets" do
    belongs_to :account, AppCount.Accounts.Account
    belongs_to :admin, AppCount.Admins.Admin

    timestamps()
  end

  @doc false
  def changeset(lock, attrs) do
    lock
    |> cast(attrs, [:admin_id, :account_id])
    |> foreign_key_constraint(:admin_id)
    |> foreign_key_constraint(:account_id)
    |> validate_required([:account_id])
  end
end
