defmodule AppCountCom.Accounts do
  import AppCountCom.Mailer.Sender, only: [send_email: 4]

  def payment_received(tenant, payment, property) do
    send_email(
      :payment_received,
      tenant.email,
      "[AppRent] Received your payment",
      tenant: tenant,
      payment: payment,
      property: property
    )
  end

  def unsuccessful_payment(payment, property) do
    send_email(
      :unsuccessful_payment,
      payment.email,
      "[AppRent] A payment has been attempted",
      payment: payment,
      property: property
    )
  end

  def payment_received_by_property_id(
        tenant,
        payment,
        property_id,
        client_schema,
        property_lookup_fn
      ) do
    property =
      AppCount.Core.ClientSchema.new(client_schema, property_id)
      |> property_lookup_fn.()

    payment_received(tenant, payment, property)
  end

  def reset_password(token, email, username, property) do
    send_email(
      :reset_password,
      email,
      "[AppRent] Reset your password",
      token: token,
      username: username,
      property: property
    )
  end

  def account_created(tenant, username, password, property) do
    send_email(
      :account_created,
      tenant.email,
      "[AppRent] Account Creation",
      tenant: tenant,
      username: username,
      password: password,
      property: property
    )
  end
end
