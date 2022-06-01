defmodule AppCountCom.Admins do
  alias AppCountCom.Mailer.Sender

  def alert_created(admin, alert) do
    Sender.send_email(
      :new_alert,
      admin.email,
      "[AppRent] You have a new alert from #{alert.sender}",
      name: admin.name,
      alert: alert,
      layout: :admin
    )
  end

  def generated_letter_ready(email, name, attachments) do
    Sender.send_email(
      :generated_letter_ready,
      email,
      "[AppRent] Your generated letter is now ready",
      name: name,
      attachments: attachments,
      layout: :admin
    )
  end

  def admin_reset_password(token, email) do
    Sender.send_email(
      :admin_reset_pw,
      email,
      "[AppRent] Reset Your Password",
      token: token,
      layout: :admin
    )
  end

  def send_daily_payments(admin, properties) do
    Sender.send_email(
      :daily_payments_email,
      admin.email,
      "[AppRent] Payments Report - 24 Hours",
      admin: admin,
      properties: properties,
      layout: :admin
    )
  end
end
