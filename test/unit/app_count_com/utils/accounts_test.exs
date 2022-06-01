defmodule AppCountCom.Mailer.AccountsCase do
  use AppCount.DataCase
  use Bamboo.Test, shared: true
  @moduletag :mailer_accounts

  test "payment_received" do
    tenant = build(:tenant, email: "someone@example.com")

    payment =
      build(:payment)
      |> Map.put(:inserted_at, AppCount.current_time())

    property =
      build(:property)
      |> Map.merge(%{icon: "http://something", logo: "http://something"})

    AppCountCom.Accounts.payment_received(tenant, payment, property)

    assert_email_delivered_with(
      subject: "[AppRent] Received your payment",
      html_body: ~r/This email is to confirm that we have received your online payment/,
      to: [
        nil: tenant.email
      ]
    )
  end
end
