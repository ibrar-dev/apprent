defmodule AppCount.Approvals do
  alias AppCount.Approvals.Utils.Approvals
  alias AppCount.Approvals.Utils.ApprovalsLogs
  alias AppCount.Approvals.Utils.ApprovalsNotes
  alias AppCount.Approvals.Utils.ApprovalsAdminData
  alias AppCount.Approvals.Utils.ApprovalCosts

  ## APPROVALS
  def list_approvals(properties, property_ids),
    do: Approvals.list_approvals(properties, property_ids)

  def list_approvals(admin_id, :pending, property_ids),
    do: Approvals.list_approvals(admin_id, :pending, property_ids)

  def chart_data(admin, property_id), do: Approvals.chart_data(admin, property_id)

  def create_approval(params, client_schema), do: Approvals.create_approval(params, client_schema)

  def update_approval(id, params, client_schema),
    do: Approvals.update_approval(id, params, client_schema)

  def delete_approval(id), do: Approvals.delete_approval(id)
  def get_next_num(payee_id, property_id), do: Approvals.get_next_num(payee_id, property_id)
  def list_approvers(admin_id), do: Approvals.list_approvers(admin_id)
  def show_approval(id, schema), do: Approvals.show_approval(id, schema)
  def delete_attachment(id), do: Approvals.delete_attachment(id)

  def list_admin_data(admin_id, property_id),
    do: ApprovalsAdminData.list_admin_data(admin_id, property_id)

  # def add_attachment()
  ## APPROVAL LOGS
  def create_approval_log(params),
    do: ApprovalsLogs.create_log(params)

  def create_approval_log_bypass(params, client_schema),
    do: ApprovalsLogs.create_approval_log_bypass(params, client_schema)

  def delete_approval_log(id, client_schema), do: ApprovalsLogs.delete_log(id, client_schema)

  def create_log_from_token(token, params, client_schema),
    do: ApprovalsLogs.create_log_from_token(token, params, client_schema)

  def gentle_reminder(params), do: ApprovalsLogs.gentle_reminder(params)
  def gentle_reminder(admin_id, note), do: ApprovalsLogs.gentle_reminder(admin_id, note)
  ## APPROVAL NOTES
  def create_approval_note(params), do: ApprovalsNotes.create_approval_note(params)
  def delete_approval_note(id), do: ApprovalsNotes.delete_approval_note(id)
  ## APPROVAL COSTS
  def get_spent(category_id, property_id), do: ApprovalCosts.get_spent(category_id, property_id)

  def list_categories_for_approval(property_id),
    do: ApprovalCosts.list_categories_for_approval(property_id)
end
