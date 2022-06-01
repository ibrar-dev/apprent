defmodule AppCount.RentApply.Process.InsertPayment do
  alias AppCount.RentApply.Process.State
  alias AppCount.Ledgers.Utils.Payments
  alias AppCount.Ledgers.Batch
  alias AppCount.Ledgers.CustomerLedger
  alias AppCount.Properties.Settings
  alias AppCount.Ledgers.Utils.SpecialChargeCodes
  alias AppCount.Ledgers.Utils.Charges
  alias Ecto.Multi
  alias AppCount.Core.ClientSchema

  def process(%State{property_id: client_schema, payment: payment} = state) do
    %{name: schema_name, attrs: %{property_id: property_id}} = client_schema

    Multi.new()
    |> create_batch(property_id)
    |> create_ledger(property_id, state.application)
    |> create_charges(payment)
    |> create_payment(payment, state.application, state.payment_process_result, state.ip_address)
    |> AppCount.Repo.transaction(prefix: schema_name)
  end

  def create_batch(multi, property_id) do
    # TODO:SCHEMA remove dasmen later
    ba_id =
      Settings.fetch_by_property_id(ClientSchema.new("dasmen", property_id)).default_bank_account_id

    cs = Batch.changeset(%Batch{}, %{property_id: property_id, bank_account_id: ba_id})
    Multi.insert(multi, :batch, cs)
  end

  def create_ledger(multi, property_id, application) do
    lease_holder =
      application["occupants"]
      |> Enum.find(fn x -> x["status"] == "Lease Holder" end)

    attrs = %{
      property_id: property_id,
      type: "applicant",
      name: lease_holder["full_name"]
    }

    cs = CustomerLedger.changeset(%CustomerLedger{}, attrs)
    Multi.insert(multi, :ledger, cs)
  end

  def create_charges(multi, payment) do
    payment
    |> fees_data
    |> Enum.map(&compute_charge/1)
    |> Enum.filter(& &1)
    |> Enum.reduce(
      multi,
      fn {charge_type, charge_attrs}, new_multi ->
        Multi.run(
          new_multi,
          charge_type,
          fn _repo, cs ->
            ClientSchema.new(
              "dasmen",
              Map.merge(charge_attrs, %{
                customer_ledger_id: cs.ledger.id,
                bill_date: AppCount.current_date(),
                status: "manual"
              })
            )
            |> Charges.create_charge()
          end
        )
      end
    )
  end

  def compute_charge(%{"name" => _, "amount" => 0}), do: nil

  def compute_charge(%{"name" => "application_fees", "amount" => amount}) do
    cc_id = SpecialChargeCodes.get_charge_code(:application_fees).id
    charge = %{amount: amount, charge_code_id: cc_id}
    {:application_fee, charge}
  end

  def compute_charge(%{"name" => "admin_fees", "amount" => amount}) do
    cc_id = SpecialChargeCodes.get_charge_code(:admin_fees).id
    charge = %{amount: amount, charge_code_id: cc_id}
    {:admin_fee, charge}
  end

  def create_payment(multi, payment, application, {:ok, payment_process_result}, ip_address) do
    Multi.run(multi, :payment, fn _repo, cs ->
      # TODO:SCHEMA remove dasmen
      Payments.create_payment(
        ClientSchema.new("dasmen", %{
          description: "Application Fee",
          agreement_text: payment["agreement_text"],
          agreement_accepted_at: payment["agreement_accepted_at"],
          source: "web",
          response: Map.delete(payment_process_result, :transaction_id),
          transaction_id: payment_process_result.transaction_id,
          property_id: cs.ledger.property_id,
          batch_id: cs.batch.id,
          amount: payment["amount"],
          payer_name: payment["payer_name"],
          payment_type: payment["payment_type"],
          last_4: payment["last_4"],
          payer_ip_address: ip_address,
          cvv_confirmed_at: AppCount.Core.Clock.now(),
          zip_code_confirmed_at: AppCount.Core.Clock.now(),
          customer_ledger_id: cs.ledger.id,
          rent_application_terms_and_conditions: application["terms_and_conditions"]
        })
      )
    end)
  end

  defp fees_data(%{"fees" => [], "amount" => a}),
    do: [%{"name" => "application_fees", "amount" => a}]

  defp fees_data(payment) do
    payment["fees"] || [%{"name" => "application_fees", "amount" => payment["amount"]}]
  end
end
