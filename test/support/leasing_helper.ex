defmodule AppCount.LeasingHelper do
  import AppCount.Factory
  alias AppCount.Repo
  alias AppCount.Ledgers.Utils.SpecialChargeCodes

  @default_params %{
    unit: nil,
    tenants: nil,
    property: nil,
    charges: [],
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

    customer =
      Map.get(params, :customer_ledger, insert(:customer_ledger, property: unit.property))

    tenancy_params =
      Map.take(params, AppCount.Tenants.Tenancy.__schema__(:fields))
      |> Map.merge(%{customer_ledger: customer, unit: unit})
      |> Map.to_list()

    tenancies =
      if params.tenants do
        Enum.map(
          params.tenants,
          &insert(:tenancy, Keyword.merge(tenancy_params, tenant: &1))
        )
      else
        [insert(:tenancy, tenancy_params)]
      end

    lease_params =
      params
      |> Map.take(AppCount.Leasing.Lease.__schema__(:fields))
      |> Map.to_list()
      |> Keyword.merge(unit: unit, customer_ledger: customer)

    lease = insert(:leasing_lease, lease_params)

    Enum.each(
      params.charges,
      fn {name, amount} ->
        special = SpecialChargeCodes.get_charge_code(name)

        if special do
          insert(
            :leasing_charge,
            lease: lease,
            amount: amount,
            charge_code: special
          )
        else
          name = "#{name}"

          account =
            AppCount.Repo.get_by(AppCount.Accounting.Account, name: name) ||
              insert(
                :account,
                name: name,
                is_credit: true
              )

          charge_code =
            Repo.get_by(AppCount.Ledgers.ChargeCode, account_id: account.id) ||
              insert(:charge_code, account: account, code: name)

          insert(
            :leasing_charge,
            lease: lease,
            amount: amount,
            charge_code: charge_code
          )
        end
      end
    )

    %{lease: lease, tenancies: tenancies}
  end
end
