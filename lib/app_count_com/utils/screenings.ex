defmodule AppCountCom.NotifyManagersScreening do
  import AppCountCom.Mailer.Sender, only: [send_email: 4]

  def notify_managers_screening(screening, tenant_safe_url, property, manager) do
    send_email(
      :notify_managers_screening,
      manager.email,
      "[AppRent] There is a screened applicant.",
      name: manager.name,
      screening: screening,
      tenant_safe_url: tenant_safe_url,
      property: property,
      layout: :property
    )
  end

  def notify_managers_instant_screening(screening, tenant_safe_url, property, manager) do
    send_email(
      :notify_managers_instant_screening,
      manager.email,
      "[AppRent] There is an instantly screened applicant.",
      name: manager.name,
      screening: screening,
      tenant_safe_url: tenant_safe_url,
      property: property,
      layout: :property
    )
  end
end
