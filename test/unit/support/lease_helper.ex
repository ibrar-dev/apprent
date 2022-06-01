defmodule AppCount.LeaseHelper do
  import AppCount.Factory
  alias AppCount.Repo
  alias AppCount.Ledgers.Utils.SpecialChargeCodes

  @default_params %{
    unit: nil,
    tenants: nil,
    property: nil,
    charges: [],
    deposit_amount: 100,
    start_date: %Date{
      year: 2018,
      month: 6,
      day: 1
    },
    end_date: %Date{
      year: 2019,
      month: 6,
      day: 1
    }
  }

  def insert_lease(params \\ %{}) do
    params = Map.merge(@default_params, params)
    unit = params.unit || insert(:unit, property: params.property || insert(:property))

    lease_params =
      params
      |> Map.to_list()
      |> Keyword.drop([:charges, :property])
      |> Keyword.merge(unit: unit, tenants: params.tenants || [insert(:tenant)])

    lease = insert(:lease, lease_params)

    Enum.each(
      params.charges,
      fn {name, amount} ->
        special = SpecialChargeCodes.get_charge_code(name)

        if special do
          AppCount.Properties.create_charge(%{
            lease_id: lease.id,
            amount: amount,
            name: name,
            charge_code_id: special.id,
            next_bill_date: params.start_date
          })
        else
          name = "#{name}"

          account =
            AppCount.Repo.get_by(AppCount.Accounting.Account, name: name) ||
              insert(
                :account,
                name: name,
                is_credit: true
              )

          charge_code_id =
            (Repo.get_by(AppCount.Ledgers.ChargeCode, account_id: account.id) ||
               insert(:charge_code, account: account)).id

          AppCount.Properties.create_charge(%{
            lease_id: lease.id,
            amount: amount,
            name: name,
            charge_code_id: charge_code_id,
            next_bill_date: params.start_date
          })
        end
      end
    )

    lease
  end
end
