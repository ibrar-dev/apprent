defmodule AppCount.Approvals.ApprovalLog do
  use Ecto.Schema
  import Ecto.Changeset

  # admin_id is the person who is creating the status of the approval. So doing the approving or denying.
  schema "admins__approval_logs" do
    field :status, :string
    field :notes, :string
    field :deleted, :boolean, default: false
    belongs_to :admin, Module.concat(["AppCount.Admins.Admin"])
    belongs_to :approval, Module.concat(["AppCount.Approvals.Approval"])

    timestamps()
  end

  @doc false
  def changeset(approval_log, attrs) do
    approval_log
    |> cast(attrs, [:status, :admin_id, :approval_id, :notes, :deleted])
    |> validate_required([:status, :admin_id])
  end
end
