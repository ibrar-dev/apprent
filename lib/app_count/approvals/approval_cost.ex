defmodule AppCount.Approvals.ApprovalCost do
  use Ecto.Schema
  import Ecto.Changeset

  schema "admins__approvals_costs" do
    field :amount, :decimal, default: 0
    belongs_to :approval, Module.concat(["AppCount.Approvals.Approval"])
    belongs_to :category, Module.concat(["AppCount.Accounting.Category"])

    timestamps()
  end

  @doc false
  def changeset(approvals_cost, attrs) do
    approvals_cost
    |> cast(attrs, [:amount, :approval_id, :category_id])
    |> validate_required([:amount, :approval_id, :category_id])
  end
end
