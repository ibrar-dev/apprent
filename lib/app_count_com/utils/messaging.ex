defmodule AppCountCom.Messaging do
  import AppCountCom.Mailer.Sender, only: [send_email: 4]

  def send_individual_email(subject, body, attachments, email) do
    send_email(
      :raw_html,
      email,
      "[AppRent] #{subject}",
      body: body,
      attachments: attachments,
      layout: :admin
    )
  end

  def send_individual_email(subject, body, attachments, email, property) do
    send_email(
      :raw_html,
      email,
      "[AppRent] #{subject}",
      body: body,
      attachments: attachments,
      property: property
    )
  end
end
