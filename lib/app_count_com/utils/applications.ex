defmodule AppCountCom.Applications do
  import AppCountCom.Mailer.Sender, only: [send_email: 4]

  def application_received(email, property, payment) do
    subject = "[AppRent] Your application to #{property.name}"
    send_email(:application_received, email, subject, property: property, payment: payment)
  end

  def application_saved(email, assigns) when is_binary(email) do
    subject = "[AppRent] Your Application Form PIN"
    send_email(:saved_form, email, subject, assigns)
  end

  def application_submitted(
        %AppCount.Admins.Admin{} = admin,
        %AppCount.Properties.Property{} = property,
        application_info
      ) do
    subject = "[AppRent] New Application - #{property.name}"

    send_email(
      :application_submitted,
      admin.email,
      subject,
      admin: admin,
      property: property,
      application_info: application_info
    )
  end

  def application_summary(admin, from_date, applications) do
    args = [applications: applications, from: from_date, layout: :admin]
    send_email(:application_summary, admin.email, "[AppRent] Application Summary", args)
  end

  def application_approved(email, application) do
    {:ok, crypt} = AppCount.Crypto.LocalCryptoServer.encrypt("#{application.id}")

    encoded_crypt =
      crypt
      |> URI.encode_www_form()

    send_email(
      :application_approved,
      email,
      "[AppRent] Application Approved",
      application: application,
      crypt: encoded_crypt,
      property: application.property
    )
  end

  def send_payment_url(property, url, first_person) do
    send_email(
      :admin_payment_url,
      first_person.email,
      "[AppRent] Administration Fee Payment Portal",
      url: url,
      first_person: first_person,
      property: property
    )
  end

  def send_daily_applications(properties, admin) do
    send_email(
      :daily_applications,
      admin.email,
      "[AppRent] Daily Application Summary",
      properties: properties,
      admin: admin,
      layout: :admin
    )
  end
end
