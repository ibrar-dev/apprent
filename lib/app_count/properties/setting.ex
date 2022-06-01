defmodule AppCount.Properties.Setting do
  use Ecto.Schema
  import Ecto.Changeset

  @moduledoc """
  If payments_accepted is false, ALL payments should not be accepted, whether that is rent_saga or applications or any other form. Nothing should be processed
  """

  @agreement_text "I understand that the initiation by me of either a one-time payment or scheduled AutoPay/recurring payments on the AppRent payment authorization page serves as my authorization for my {Property Entity Name} (or its third-party agent on its behalf), and the financial institution designated (or any other financial institution I may authorize at any time), to withdraw the specified payment(s) from my designated checking/savings account or charge my designated credit/debit card for the specified payment(s), as applicable, in accordance with the payment instructions specified by me on such payment authorization page. I further understand that my election of scheduled AutoPay/recurring payments shall serve as my ongoing authorization for each monthly scheduled payment in accordance with the payment instructions specified by me on the AppRent payment authorization page, and shall remain in effect until I terminate such election on the AppRent payment authorization page. If the payment date selected by me falls on a weekend or holiday, I understand that the payment may be executed on the next business day. I agree that no prior notification will be provided to me for each scheduled payment, but a receipt will be emailed to me for each payment.\nUnless prohibited by law, payments by credit/debit card involve a processing fee of 3%, which will be added to the amount of your payment.  In the case a payment by withdrawal from my designated checking/savings account is rejected for Non-Sufficient Funds (NSF), I understand that my [property management company] (or its third-party agent on its behalf) may, in its discretion, attempt to process the charge again within 30 days, and I agree to pay an additional charge for each attempt returned NSF which will be initiated as a separate transaction from the authorized payment.\nI agree to promptly update my checking/savings account and/or credit/debit card information on the AppRent payment authorization page if it changes, but in any event at least fifteen (15) calendar days prior to the next payment date to prevent any delay in payment processing. I certify that I am an authorized user of my designated checking/savings account or my designated credit/debit card, as applicable, and will not dispute the scheduled transactions with my bank or credit/debit card company; provided the transactions are made in accordance with the payment instructions specified by me on the AppRent payment authorization page."

  schema "properties__settings" do
    field :accepts_partial_payments, :boolean, default: true
    field :active, :boolean, default: true
    field :admin_fee, :decimal, default: 150
    field :agreement_text, :string, default: @agreement_text
    field :applicant_info_visible, :boolean, default: true
    field :application_fee, :decimal, default: 50
    field :applications, :boolean, default: true
    field :area_rate, :decimal, default: 1
    field :daily_late_fee_addition, :decimal, default: 0
    field :grace_period, :integer, default: 7
    field :instant_screen, :boolean, default: false
    field :late_fee_amount, :decimal, default: 50
    field :late_fee_threshold, :decimal, default: 50
    field :late_fee_type, :string, default: "$"
    field :mtm_fee, :integer, default: 250
    field :mtm_multiplier, :decimal, default: 250
    field :notice_period, :integer, default: 30
    field :nsf_fee, :integer, default: 50
    field :payments_accepted, :boolean, default: true
    field :renewal_overage_threshold, :integer, default: 25
    field :rewards, :boolean, default: true
    field :tours, :boolean, default: true
    field :integration, :string
    field :sync_payments, :boolean
    field :sync_ledgers, :boolean
    field :sync_residents, :boolean
    field :verification_form, :string, default: ""
    belongs_to :property, AppCount.Properties.Property
    belongs_to :default_bank_account, AppCount.Accounting.BankAccount

    timestamps()
  end

  @doc false
  def changeset(setting, attrs) do
    setting
    |> cast(
      attrs,
      [
        :accepts_partial_payments,
        :active,
        :admin_fee,
        :agreement_text,
        :applicant_info_visible,
        :application_fee,
        :application_fee,
        :applications,
        :area_rate,
        :daily_late_fee_addition,
        :default_bank_account_id,
        :grace_period,
        :instant_screen,
        :late_fee_amount,
        :late_fee_threshold,
        :late_fee_type,
        :mtm_fee,
        :mtm_multiplier,
        :notice_period,
        :nsf_fee,
        :property_id,
        :payments_accepted,
        :renewal_overage_threshold,
        :rewards,
        :tours,
        :verification_form,
        :integration,
        :sync_payments,
        :sync_ledgers,
        :sync_residents
      ]
    )
    |> validate_required([
      :accepts_partial_payments,
      :admin_fee,
      :agreement_text,
      :applicant_info_visible,
      :application_fee,
      :applications,
      :area_rate,
      :daily_late_fee_addition,
      :grace_period,
      :instant_screen,
      :late_fee_amount,
      :late_fee_threshold,
      :late_fee_type,
      :mtm_fee,
      :mtm_multiplier,
      :notice_period,
      :nsf_fee,
      :property_id,
      :payments_accepted,
      :renewal_overage_threshold,
      :tours
    ])
  end
end
