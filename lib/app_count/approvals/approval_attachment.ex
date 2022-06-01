defmodule AppCount.Approvals.ApprovalAttachment do
  use Ecto.Schema
  import Ecto.Changeset
  use AppCount.EctoTypes.Attachment

  schema "admins__approval_attachments" do
    belongs_to :approval, Module.concat(["AppCount.Approvals.Approval"])
    attachment(:attachment)

    timestamps()
  end

  @doc false
  def changeset(approval_attachment, attrs) do
    approval_attachment
    |> cast(attrs, [:approval_id, :attachment_id])
    |> cast_attachment(:attachment)
    |> validate_required([:approval_id, :attachment])
  end
end
