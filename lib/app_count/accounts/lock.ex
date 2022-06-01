defmodule AppCount.Accounts.Lock do
  use Ecto.Schema
  import Ecto.Changeset

  schema "accounts__locks" do
    field :comments, :string
    field :enabled, :boolean
    field :reason, :string
    belongs_to :account, AppCount.Accounts.Account
    belongs_to :admin, AppCount.Admins.Admin

    timestamps()
  end

  @doc false
  def changeset(lock, attrs) do
    lock
    |> cast(attrs, [
      :reason,
      :enabled,
      :comments,
      :admin_id,
      :account_id,
      :inserted_at,
      :updated_at
    ])
    |> validate_required([:reason, :account_id])
  end
end
