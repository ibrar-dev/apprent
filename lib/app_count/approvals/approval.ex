defmodule AppCount.Approvals.Approval do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset

  schema "admins__approvals" do
    field :notes, :string
    field :type, :string
    field :num, :string
    field :params, :map
    belongs_to :admin, AppCount.Admins.Admin
    belongs_to :property, AppCount.Properties.Property
    has_many :attachments, AppCount.Approvals.ApprovalAttachment
    has_many :approval_logs, AppCount.Approvals.ApprovalLog, foreign_key: :approval_id
    has_many :approval_notes, AppCount.Approvals.ApprovalNote
    has_many :approval_costs, AppCount.Approvals.ApprovalCost

    timestamps()
  end

  @doc false
  def changeset(approval, attrs) do
    approval
    |> cast(attrs, [:notes, :type, :num, :params, :admin_id, :property_id, :inserted_at])
    # |> cast_assoc(:approval_logs, with: &AppCount.Approvals.ApprovalLog.changeset/2)
    |> unique_constraint(:approval_number,
      name: :admins__approvals_num_type_index,
      message: "already taken for this approval type"
    )
    |> validate_required([:admin_id, :property_id, :num, :type, :params])
  end

  def migrate_params_cost() do
    from(
      a in AppCount.Approvals.Approval,
      join: c in assoc(a, :approval_costs),
      select: %{
        id: a.id,
        amount: fragment("(params->>'amount')"),
        costs: sum(c.amount),
        params: a.params
      },
      group_by: [a.id]
    )
    |> AppCount.Repo.all()
    |> Enum.filter(&(!Decimal.equal?(Decimal.new(&1.amount), &1.costs)))
    |> Enum.each(fn a ->
      AppCount.Repo.get(AppCount.Approvals.Approval, a.id)
      |> AppCount.Approvals.Approval.changeset(Map.put(a.params, "amount", a.costs))
      |> AppCount.Repo.update()
    end)
  end
end
