defmodule AppCount.Approvals.ApprovalNote do
  use Ecto.Schema
  import Ecto.Changeset

  schema "admins__approvals_notes" do
    field :note, :string
    belongs_to :admin, AppCount.Admins.Admin
    belongs_to :approval, AppCount.Approvals.Approval

    timestamps()
  end

  @doc false
  def changeset(approval_note, attrs) do
    approval_note
    |> cast(attrs, [:note, :admin_id, :approval_id])
    |> validate_required([:note, :admin_id, :approval_id])
  end
end
