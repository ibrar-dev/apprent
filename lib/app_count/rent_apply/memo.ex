defmodule AppCount.RentApply.Memo do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.RentApply.Memo

  schema "rent_apply__memos" do
    field(:note, :string)

    belongs_to(:application, Module.concat(["AppCount.RentApply.RentApplication"]),
      foreign_key: :application_id
    )

    belongs_to(:admin, Module.concat(["AppCount.Admins.Admin"]))

    timestamps()
  end

  @doc false
  def changeset(%Memo{} = memo, attrs) do
    memo
    |> cast(attrs, [:note, :application_id, :admin_id])
    |> validate_required([:note, :application_id, :admin_id])
  end
end
