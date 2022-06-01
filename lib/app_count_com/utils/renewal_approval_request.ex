defmodule AppCountCom.RenewalApprovalRequest do
  import AppCountCom.Mailer.Sender, only: [send_email: 4]

  def renewal_approval_request(property, regional, admin, renewal_period) do
    send_email(
      :renewal_approval_request,
      regional.email,
      "[AppRent] You have a renewal request for you",
      name: regional.name,
      admin_name: admin.name,
      renewal_period: renewal_period,
      url: "#{AppCount.namespaced_url(:administration)}/leases/renewals",
      property: property,
      layout: :property
    )
  end

  def notify_pm_approval(manager, resident, property, package, lease_id) do
    send_email(
      :notify_pm_approval,
      manager.email,
      "[AppRent] A resident has chosen a renewal package.",
      manager_name: manager.name,
      resident_name: "#{resident.first_name} #{resident.last_name}",
      package: package,
      url: "#{AppCount.namespaced_url(:administration)}/leases/#{lease_id}/new",
      property: property,
      layout: :property
    )
  end
end
