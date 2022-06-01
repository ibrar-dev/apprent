defmodule AppCountCom.Tenants do
  import AppCountCom.Mailer.Sender, only: [send_email: 4]
  alias AppCount.Tenants.Tenant

  def new_tenant(%{email: email} = tenant, password \\ nil, payment \\ nil) do
    send_email(
      :new_tenant,
      email,
      "[AppRent] Welcome to #{tenant.property.name}!",
      tenant: tenant,
      property: tenant.property,
      payment: payment,
      password: password
    )
  end

  def new_resident_event(resident_info, event) do
    send_email(
      :new_resident_event,
      resident_info.email,
      "[AppRent] New Event - #{event.name}!",
      resident: resident_info.name,
      property: resident_info.property,
      name: event.name,
      location: event.location,
      date: event.date,
      info: event.info,
      image: event.image,
      start_time: event.start_time
    )
  end

  def new_resident_letter(%{property: property, tenant: tenant} = _resident_info, letter_name) do
    send_email(
      :new_resident_letter,
      tenant.email,
      "[AppRent] New Letter",
      name: "#{tenant.first_name} #{tenant.last_name}",
      letter: letter_name,
      property: property
    )
  end

  # Property should come in from `AppCount.Properties.get_property/1
  # Tenant should be an %AppCount.Tenants.Tenant{} struct, by itself or in
  # aggregate
  #
  # Send when the tenant is marked as cash only to tell them their autopays have been deactivated
  def tenant_marked_as_cash_only(%{property: property, tenant: tenant}) do
    send_email(
      :cash_only_tenant_letter,
      {"#{tenant.first_name} #{tenant.last_name}", tenant.email},
      "[AppRent] Account Locked",
      first_name: tenant.first_name,
      property: property
    )
  end

  # We expect a %Tenant{} aggregate as well as a Property from AppCount.Properties.get_property/1
  #
  # Send whenever an autopay record is created or switched to active: true
  def autopay_activated(%{
        property: property,
        tenant: %Tenant{aggregate: true} = tenant
      }) do
    last_4 = tenant.account.autopay.payment_source.last_4

    send_email(
      :autopay_activated,
      {"#{tenant.first_name} #{tenant.last_name}", tenant.email},
      "[AppRent] Autopay Activated",
      first_name: tenant.first_name,
      last_4: last_4,
      property: property
    )
  end

  # We expect a %Tenant{} aggregate as well as a Property from AppCount.Properties.get_property/1
  #
  # Send whenever an autopay is deactivated
  def autopay_deactivated(%{property: property, tenant: tenant}) do
    send_email(
      :autopay_deactivated,
      {"#{tenant.first_name} #{tenant.last_name}", tenant.email},
      "[AppRent] Autopay Deactivated",
      first_name: tenant.first_name,
      property: property
    )
  end

  # Property should come in from `AppCount.Properties.get_property/1
  # Tenant should be an %AppCount.Tenants.Tenant{} struct, by itself or in
  # aggregate
  #
  # Send ~24h before the autopay is billed, so typically on the last of the month
  def autopay_reminder(%{
        property: property,
        tenant: %Tenant{aggregate: true} = tenant
      }) do
    last_4 = tenant.account.autopay.payment_source.last_4

    send_email(
      :autopay_reminder,
      {"#{tenant.first_name} #{tenant.last_name}", tenant.email},
      "[AppRent] Autopay Reminder",
      first_name: tenant.first_name,
      last_4: last_4,
      property: property
    )
  end
end
