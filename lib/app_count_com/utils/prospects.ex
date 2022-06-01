defmodule AppCountCom.Prospects do
  import AppCountCom.Mailer.Sender, only: [send_email: 4]

  def contact_prospect(memo_info) do
    send_email(
      :contact_prospect,
      memo_info.prospect.email,
      "[AppRent] #{memo_info.admin} is reaching out to you from #{memo_info.property.name}",
      notes: memo_info.notes,
      admin: memo_info.admin,
      prospect: memo_info.prospect,
      property: memo_info.property
    )
  end

  def notify_of_closure(info) do
    send_email(
      :notify_of_closure,
      info.email,
      "[AppRent] A tour you have scheduled needs to be re-scheduled",
      info: info,
      property: info.property
    )
  end
end
