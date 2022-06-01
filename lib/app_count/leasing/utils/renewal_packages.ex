defmodule AppCount.Leasing.Utils.RenewalPackages do
  alias AppCount.Repo
  alias AppCount.Properties
  alias AppCount.Leasing.Lease
  alias AppCount.Accounting
  alias AppCount.Leasing.RenewalPackage
  import Ecto.Query
  import AppCount.EctoExtensions
  use AppCount.Decimal
  alias AppCount.Core.ClientSchema

  def create_renewal_package(%ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    %RenewalPackage{}
    |> RenewalPackage.changeset(params)
    |> Repo.insert(prefix: client_schema)
  end

  def add_note(
        %ClientSchema{
          name: client_schema,
          attrs: id
        },
        text,
        admin
      ) do
    pack = Repo.get(RenewalPackage, id, prefix: client_schema)

    notes =
      pack.notes ++ [%{"text" => text, "admin" => admin.name, "time" => AppCount.current_time()}]

    pack
    |> RenewalPackage.changeset(%{notes: notes})
    |> Repo.update(prefix: client_schema)
  end

  @spec package_price(%Lease{}, integer, %Date{}) :: float
  def package_price(
        %ClientSchema{
          name: client_schema,
          attrs: lease
        },
        num_months,
        start_date
      ) do
    from(
      rp in RenewalPackage,
      left_join: cp in assoc(rp, :custom_packages),
      on: cp.renewal_package_id == rp.id and cp.lease_id == ^lease.id,
      join: p in assoc(rp, :renewal_period),
      where: p.property_id == ^lease.unit.property_id,
      where: not is_nil(p.approval_admin),
      where: between(^num_months, rp.min, rp.max),
      where: between(^start_date, p.start_date, p.end_date),
      select: map(rp, [:amount, :base, :dollar]),
      select_merge: %{
        custom_amount: type(cp.amount, :float)
      }
    )
    |> Repo.one(prefix: client_schema)
    |> calculate_package_price(%ClientSchema{
      name: client_schema,
      attrs: lease
    })
  end

  defp calculate_package_price(nil, _), do: 0
  defp calculate_package_price(%{custom_amount: amount}, _) when not is_nil(amount), do: amount

  defp calculate_package_price(%{amount: amount, base: "Current Rent", dollar: true}, lease) do
    current_rent(lease) + amount
  end

  defp calculate_package_price(%{amount: amount, base: "Current Rent", dollar: false}, lease) do
    current_rent(lease) * (1 + amount * 0.01)
  end

  defp calculate_package_price(
         %{amount: amount, base: "Market Rent", dollar: true},
         %ClientSchema{
           name: client_schema,
           attrs: lease
         }
       ) do
    Properties.market_rent(%ClientSchema{
      name: client_schema,
      attrs: lease.unit.id
    }) + amount
  end

  defp calculate_package_price(
         %{amount: amount, base: "Market Rent", dollar: false},
         %ClientSchema{
           name: client_schema,
           attrs: lease
         }
       ) do
    Properties.market_rent(%ClientSchema{
      name: client_schema,
      attrs: lease.unit.id
    }) * (1 + amount * 0.01)
  end

  def current_rent(%ClientSchema{
        name: client_schema,
        attrs: lease
      }) do
    from(
      l in Lease,
      join: c in assoc(l, :charges),
      where: l.id == ^lease.id,
      where: is_nil(c.to_date) or c.to_date >= ^AppCount.current_date(),
      where:
        c.charge_code_id == ^Accounting.SpecialAccounts.get_charge_code(:rent).id or
          c.charge_code_id == ^Accounting.SpecialAccounts.get_charge_code(:hap_rent).id,
      select: sum(c.amount)
    )
    |> Repo.one(prefix: client_schema)
  end
end
