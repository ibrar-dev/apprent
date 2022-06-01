defmodule AppCountCom.Rewards do
  import AppCountCom.Mailer.Sender, only: [send_email: 4]

  def purchase_tenant(purchase, property) do
    send_email(
      :purchase_tenant,
      purchase.tenant.email,
      "[Apprent] DASMEN Reward Purchased",
      property: property,
      purchase: purchase
    )
  end
end
