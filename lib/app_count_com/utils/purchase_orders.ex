defmodule AppCountCom.PurchaseOrders do
  import AppCountCom.Mailer.Sender, only: [send_email: 4]

  def send_for_approval(supervisor, property, creator, link_to_purchases) do
    send_email(
      :send_for_approval,
      supervisor.email,
      "[AppRent] New purchase order pending approval.",
      name: supervisor.name,
      link_to_purchases: link_to_purchases,
      creator: creator,
      property: property,
      layout: :property
    )
  end
end
