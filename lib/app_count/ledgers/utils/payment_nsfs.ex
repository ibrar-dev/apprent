defmodule AppCount.Ledgers.Utils.PaymentNSFs do
  alias AppCount.Repo
  alias AppCount.Accounting
  alias AppCount.Accounts
  alias AppCount.Ledgers.Charge
  alias AppCount.Ledgers.Payment
  alias AppCount.Ledgers.Utils.Charges
  import Ecto.Query
  alias AppCount.Core.ClientSchema

  def create_nsf(%AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    ledger =
      AppCount.Ledgers.CustomerLedgerRepo.get(params["customer_ledger_id"], prefix: client_schema)

    property_id = ledger.property_id

    nsf_fee =
      Repo.get_by(AppCount.Properties.Setting, [property_id: property_id], prefix: client_schema).nsf_fee

    charges = Map.merge(params, %{"amount" => nsf_fee})
    amount = Repo.get(Payment, params["nsf_id"], prefix: client_schema).amount

    nsf_charge_code = Accounting.SpecialAccounts.get_charge_code(:nsf_fees)

    post_month =
      AppCount.current_date()
      |> Timex.beginning_of_month()

    charge_params =
      Map.merge(
        params,
        %{
          "amount" => amount,
          "charge_code_id" => nsf_charge_code.id,
          "status" => "manual",
          "post_month" => post_month
        }
      )

    charge =
      %Charge{}
      |> Charge.changeset(charge_params)
      |> Repo.insert(prefix: client_schema)

    ClientSchema.new(client_schema, charge)
    |> lock_account()
    |> void_payment()
    |> add_charge(charges)
  end

  defp add_charge({:error, e}, _params), do: {:error, e}

  defp add_charge(
         {:ok,
          %AppCount.Core.ClientSchema{
            name: client_schema,
            attrs: _nsf
          }},
         params
       ) do
    params =
      Map.merge(
        params,
        %{
          "bill_date" => params["bill_date"],
          "charge_code_id" => Accounting.SpecialAccounts.get_charge_code(:nsf_fees).id,
          "description" => "NSF Charge",
          "status" => "manual",
          "nsf_id" => nil,
          "image" => nil
        }
      )

    Charges.create_charge(ClientSchema.new(client_schema, params))
  end

  def get_nsf_proof(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: id
      }) do
    from(
      nsf in Charge,
      join: proof in assoc(nsf, :image),
      join: proof_url in assoc(nsf, :image_url),
      where: nsf.id == ^id,
      select: %{
        content_type: proof.content_type,
        url: proof_url.url
      }
    )
    |> Repo.one(prefix: client_schema)
  end

  defp lock_account(%AppCount.Core.ClientSchema{
         name: client_schema,
         attrs: {:ok, %{nsf_id: payment_id} = p}
       }) do
    case Repo.get(Payment, payment_id, prefix: client_schema).tenant_id do
      nil -> nil
      tenant_id -> Accounts.lock_account(tenant_id, "NSF charges")
    end

    {:ok,
     %AppCount.Core.ClientSchema{
       name: client_schema,
       attrs: p
     }}
  end

  defp lock_account(e), do: e

  defp void_payment(
         {:ok,
          %AppCount.Core.ClientSchema{
            name: client_schema,
            attrs: %{nsf_id: payment_id} = p
          }}
       ) do
    Payment
    |> Repo.get(payment_id, prefix: client_schema)
    |> Payment.changeset(%{status: "nsf"})
    |> Repo.update(prefix: client_schema)

    {:ok,
     %AppCount.Core.ClientSchema{
       name: client_schema,
       attrs: p
     }}
  end

  defp void_payment(e), do: e
end
