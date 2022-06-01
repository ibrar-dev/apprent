defmodule AppCountCom.Mailer.AdminsCase do
  use AppCount.DataCase
  use Bamboo.Test, shared: true
  alias AppCount.Admins.Alert
  @moduletag :mailer_admins

  test "alert_created" do
    alert = %Alert{sender: "send", note: "Some note"}

    AppCountCom.Admins.alert_created(
      %{email: "someone@something.com", name: "Generic Person"},
      alert
    )

    assert_email_delivered_with(
      subject: "[AppRent] You have a new alert from #{alert.sender}",
      html_body: ~r/#{alert.note}/,
      to: [nil: "someone@something.com"]
    )
  end

  test "generated_letter_ready" do
    attachments = %Plug.Upload{
      content_type: "application/pdf",
      filename: "generated_letters.pdf",
      path: Path.expand("../../resources/Sample1.pdf", __DIR__)
    }

    AppCountCom.Admins.generated_letter_ready("someone@something.com", "Generic Person", [
      attachments
    ])

    assert_email_delivered_with(
      subject: "[AppRent] Your generated letter is now ready",
      html_body: ~r/Please see the attached file for your letters/,
      to: [nil: "someone@something.com"]
    )
  end

  test "admin_reset_password" do
    AppCountCom.Admins.admin_reset_password("ABCDEFG", "someone@something.com")

    assert_email_delivered_with(
      subject: "[AppRent] Reset Your Password",
      html_body: ~r/ABCDEFG/,
      to: [nil: "someone@something.com"]
    )
  end
end
