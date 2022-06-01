defmodule AppCount.Approvals.ApprovalRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Approvals.Approval,
    preloads: [
      attachments: [:attachment, :attachment_url],
      admin: [],
      property: [],
      approval_logs: [:admin],
      approval_notes: [:admin],
      approval_costs: [:category]
    ]

  def list_approvals(property_ids) do
    from(
      a in @schema,
      preload: ^@preloads,
      where: a.property_id in ^property_ids,
      order_by: [
        asc: :inserted_at
      ]
    )
    |> Repo.all()
  end
end
