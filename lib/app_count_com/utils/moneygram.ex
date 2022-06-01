defmodule AppCountCom.MoneyGram do
  import AppCountCom.Mailer.Sender, only: [send_email: 4]

  def daily_money_gram_payments(admin, property_payments) do
    send_email(
      :daily_moneygram_report,
      admin.email,
      "[AppRent] Daily MoneyGram Payments Summary",
      property_payments: property_payments,
      admin: admin,
      layout: :admin
    )
  end
end
