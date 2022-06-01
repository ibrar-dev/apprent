defmodule AppCountCom.Approvals do
  import AppCountCom.Mailer.Sender, only: [send_email: 4]

  def notify_approval_status(approval, admin, log, token, property) do
    send_email(
      :notify_approval_status,
      approval.requestor.email,
      "[AppRent Approvals] #{admin.name} has updated the status of your approval.",
      requestor: approval.requestor,
      admin: admin,
      log: log,
      token: token,
      approval: approval,
      property: property
    )
  end

  def notify_pending_of_approval(approval, admin, log, token, property) do
    send_email(
      :notify_pending_of_approval,
      admin.email,
      "[AppRent Approvals] #{approval.requestor.name} has requested your approval.",
      requestor: approval.requestor,
      admin: admin,
      log: log,
      token: token,
      approval: approval,
      property: property
    )
  end

  def gentle_reminder_note(approval, admin, note, property) do
    send_email(
      :gentle_reminder_note,
      admin.email,
      "[AppRent Approvals] #{note.admin.name} has mentioned you in a note on an approval.",
      requestor: note.admin,
      admin: admin,
      note: note,
      approval: approval,
      property: property
    )
  end

  def gentle_reminder(approval, admin, bugger, property) do
    send_email(
      :gentle_reminder,
      admin.email,
      "[AppRent Approvals] #{bugger.name} is reminding you of an approval request.",
      admin: admin,
      bugger: bugger,
      approval: approval,
      property: property
    )
  end

  def daily_pending_approvals(admin, pending) do
    send_email(
      :daily_pending_approvals,
      admin.email,
      "[AppRent Approvals] Here are the approvals that still require your attention.",
      admin: admin,
      pending: pending,
      layout: :admin
    )
  end
end
