defmodule AppCountCom.Packages do
  import AppCountCom.Mailer.Sender, only: [send_email: 4]

  def package_created(property, tenant, package) do
    if tenant.email != nil do
      send_email(
        :package_created,
        tenant.email,
        "[AppRent] You have a package waiting for you",
        name: "#{tenant.first_name} #{tenant.last_name}",
        pin: tenant.package_pin,
        package: package,
        type: package.type,
        property: property
      )
    else
      raise "noEmail"
    end
  end

  def package_uncollected(property, tenant, info) do
    send_email(
      :package_uncollected,
      tenant.email,
      "[AppRent] You have a package waiting for you",
      name: "#{tenant.first_name} #{tenant.last_name}",
      pin: tenant.package_pin,
      info: info,
      total: info.total,
      property: property
    )
  end
end
