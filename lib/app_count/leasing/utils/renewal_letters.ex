defmodule AppCount.Leasing.Utils.RenewalLetters do
  import Ecto.Query
  alias AppCount.Leasing.RenewalPeriod
  alias AppCount.Leasing.RenewalPackage
  alias AppCount.Leasing.CustomPackage
  alias AppCount.Repo
  alias AppCount.Data
  alias AppCount.Properties
  import AppCount.EctoExtensions
  alias AppCount.Core.ClientSchema

  # required for all letters:
  # property_info: name, address, city, state, zip, contact_email?, setting|days for notice, mtm_fee
  # dasmen logo
  # resident info: full name
  # lease info: unit_address, unit_number, lease_end
  # unit_info: market rent, floor plan lease breakdown

  # pacakges: min-max, rent_amount, total new amount

  def renewal_letter_view_module do
    # FIX_DEPS
    Module.concat(["AppCountWeb.Letters.RenewalLetterView"])
  end

  def generate(%ClientSchema{name: client_schema, attrs: period_id}) do
    period = Repo.get(RenewalPeriod, period_id, prefix: client_schema)
    property = get_property_info(%ClientSchema{name: client_schema, attrs: period.property_id})
    packages = get_packages(%ClientSchema{name: client_schema, attrs: period.id})

    %ClientSchema{name: client_schema, attrs: period}
    |> get_leases
    |> Enum.map(fn lease ->
      custom_packages =
        get_custom_packages(
          %ClientSchema{name: client_schema, attrs: period.id},
          lease.id
        )

      if(length(custom_packages) != 0) do
        Map.merge(
          lease,
          %{
            property: property,
            packages: [],
            custom_packages: custom_packages,
            period: period
          }
        )
      else
        Map.merge(lease, %{property: property, packages: packages, period: period})
      end
    end)
    |> generate_pdf_data
  end

  def generate_pdf_data(info) do
    # FIX_DEPS
    Enum.map(
      info,
      fn l ->
        Phoenix.View.render_to_string(renewal_letter_view_module(), "index.html", l)
        |> PdfGenerator.generate_binary()
        |> save_to_aws(l)
      end
    )
  end

  defp save_to_aws({:error, _}, %{tenants: tenants}) do
    %{error: "#{hd(tenants)["id"]}"}
  end

  defp save_to_aws({:ok, binary}, %{tenants: tenants} = info) do
    date_stamp = Timex.format!(AppCount.current_time(), "{M}_{D}_{YYYY}")
    filename = "#{info.period.id}_#{hd(tenants)["id"]}_#{date_stamp}_Renewal_Offer"
    uuid = Data.binary_to_upload(binary, filename, "application/pdf")

    Enum.map(tenants, fn t -> t["id"] end)
    |> Enum.map(fn t -> save_to_resident(t, uuid, filename) end)
  end

  defp save_to_resident(tenant_id, uuid, filename) do
    %{
      document: %{
        "uuid" => uuid
      },
      name: filename,
      tenant_id: tenant_id,
      type: "Renewal Offer",
      visible: true
    }
    |> Properties.create_document()
    |> case do
      {:ok, _} -> %{ok: tenant_id}
      _ -> %{error: tenant_id}
    end
  end

  defp get_property_info(%ClientSchema{name: client_schema, attrs: property_id}) do
    from(
      p in Properties.Property,
      left_join: i in assoc(p, :icon_url),
      join: s in assoc(p, :setting),
      where: p.id == ^property_id,
      select: %{
        id: p.id,
        name: p.name,
        address: p.address,
        notice_period: s.notice_period,
        mtm_fee: s.mtm_fee,
        group_email: p.group_email,
        icon: i.url
      },
      limit: 1
    )
    |> Repo.one(prefix: client_schema)
  end

  defp get_leases(%ClientSchema{
         name: client_schema,
         attrs: %{property_id: property_id, start_date: start_date, end_date: end_date}
       }) do
    mr_sub =
      from(
        u in Properties.Unit,
        left_join: f in assoc(u, :features),
        left_join: plan in assoc(u, :floor_plan),
        left_join: fp in assoc(plan, :features),
        left_join: dc in assoc(plan, :default_charges),
        left_join: cc in assoc(dc, :charge_code),
        where: is_nil(f.stop_date),
        where: is_nil(fp.stop_date),
        select: %{
          unit_id: u.id,
          features: jsonize(dc, [:id, :price, :default_charge, {:name, cc.name}]),
          market_rent: coalesce(sum(f.price), 0) + coalesce(sum(fp.price), 0)
        },
        group_by: [u.id, fp.price]
      )

    from(
      l in AppCount.Leasing.Lease,
      join: u in assoc(l, :unit),
      join: te in assoc(l, :tenancies),
      left_join: mr in subquery(mr_sub),
      on: u.id == mr.unit_id,
      join: c in assoc(l, :charges),
      join: cc in assoc(c, :charge_code),
      join: t in assoc(te, :tenant),
      where:
        is_nil(te.actual_move_out) and is_nil(te.notice_date) and u.property_id == ^property_id and
          is_nil(l.renewal_package_id),
      where: l.end_date <= ^end_date and l.end_date >= ^start_date,
      select: %{
        id: l.id,
        unit: u.number,
        address: u.address,
        start_date: l.start_date,
        end_date: l.end_date,
        market_rent: mr.market_rent,
        features: mr.features,
        charges: jsonize(c, [:id, :amount, :to_date, {:account, cc.name}]),
        tenants: jsonize(t, [:id, :first_name, :last_name])
      },
      order_by: [
        asc: u.number,
        desc: l.start_date
      ],
      distinct: l.customer_ledger_id,
      group_by: [l.id, u.id, mr.market_rent, mr.features]
    )
    |> Repo.all(prefix: client_schema)
  end

  defp get_packages(%ClientSchema{name: client_schema, attrs: id}) do
    from(
      p in RenewalPackage,
      where: p.renewal_period_id == ^id,
      select: %{
        id: p.id,
        min: p.min,
        max: p.max,
        base: p.base,
        amount: p.amount,
        dollar: p.dollar
      },
      order_by: [
        asc: :min
      ]
    )
    |> Repo.all(prefix: client_schema)
  end

  defp get_custom_packages(
         %ClientSchema{name: client_schema, attrs: period_id},
         lease_id
       ) do
    from(
      p in CustomPackage,
      join: pe in assoc(p, :renewal_package),
      where: pe.renewal_period_id == ^period_id and p.lease_id == ^lease_id,
      select: %{
        id: p.id,
        min: pe.min,
        max: pe.max,
        amount: p.amount
      },
      order_by: [
        asc: pe.min
      ]
    )
    |> Repo.all(prefix: client_schema)
  end
end
