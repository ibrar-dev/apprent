defmodule AppCount.Tenants.Utils.CreateTenant do
  import Ecto.Query
  import AppCount.EctoExtensions
  import AppCount.Utils, only: [indifferent: 2, matched_put: 3]
  alias AppCount.Repo
  alias AppCount.Accounting
  alias AppCount.Leases
  alias AppCount.Properties.Charge
  alias AppCount.Properties.Occupancy
  alias AppCount.Properties.Occupant
  alias AppCount.Tenants.Tenant
  alias AppCount.RentApply.RentApplication
  alias AppCount.Ledgers.Payment
  alias AppCount.Ledgers.Utils.Charges
  alias AppCount.Leases.Lease
  alias AppCount.Leases.Form
  alias Ecto.Multi
  use AppCount.Decimal
  alias AppCount.Core.ClientSchema

  def create_tenant(params, opts \\ [])

  def create_tenant(params, lease_id: lease_id) do
    new_params =
      merge_package_pin(params)
      |> merge_uuid
      |> uniformalize_keys

    Multi.new()
    |> Multi.insert(:tenant, Tenant.changeset(%Tenant{}, new_params))
    |> Multi.run(
      :occupancy,
      fn _repo, cs ->
        %Occupancy{}
        |> Occupancy.changeset(%{"tenant_id" => cs.tenant.id, "lease_id" => lease_id})
        |> Repo.insert()
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, r} ->
        AppCount.Core.Tasker.start(fn ->
          update_bluemoon_lease(params["admin"], lease_id)
        end)

        {:ok, r}

      {:error, _, %{errors: [{f, {error, _}}]}, _} ->
        field =
          String.replace("#{f}", ~r/_id/, "")
          |> String.capitalize()

        {:error, "#{field} #{error}"}
    end
  end

  def create_tenant(params, opts) do
    new_params =
      params
      |> merge_package_pin
      |> merge_uuid
      |> uniformalize_keys

    Multi.new()
    |> Multi.insert(:lease, Lease.changeset(%Lease{}, new_params))
    |> attach_lease_form(opts[:application_id])
    |> Multi.run(
      :tenants,
      fn _repo, _cs ->
        new_params
        |> indifferent(:persons)
        |> Enum.filter(&(indifferent(&1, :status) == "Lease Holder"))
        |> Enum.map(&matched_put(&1, :application_id, opts[:application_id]))
        |> Enum.reduce_while({:ok, []}, &insert_tenant/2)
      end
    )
    |> Multi.run(
      :occupancies,
      fn _repo, cs ->
        Enum.reduce_while(cs.tenants, {:ok, []}, &insert_occupancy(&1, &2, cs.lease.id))
      end
    )
    |> Multi.run(
      :occupants,
      fn _repo, cs ->
        new_params
        |> indifferent(:persons)
        |> Enum.filter(&(&1["status"] != "Lease Holder"))
        |> Enum.reduce_while({:ok, cs}, &insert_occupant(&1, &2, cs.lease.id))
      end
    )
    |> Multi.run(
      :sec_charge,
      fn _repo, cs ->
        AppCount.Leases.Utils.Leases.create_sec_dep_charge(cs.lease) || {:ok, cs}
      end
    )
    |> add_application_charges_to_ledger(opts[:application_id])
    |> Multi.run(
      :charges,
      fn _repo, cs ->
        new_params
        |> indifferent(:charges)
        |> Enum.reduce_while({:ok, []}, &insert_charge(&1, &2, cs.lease))
      end
    )
    |> update_application_payments(opts[:application_id])
    |> Repo.transaction()
    |> notify_tenant
  end

  def create_new_tenant(params) do
    Multi.new()
    |> Multi.insert(:lease, Lease.changeset(%Lease{}, params))
    |> Multi.run(:create_tenant, fn _repo, cs -> create_tenant(params, lease_id: cs.lease.id) end)
    |> Multi.run(
      :create_charges,
      fn _repo, cs ->
        charges = params["charges"] || params.charges || []

        charges
        |> Enum.reduce_while({:ok, []}, &insert_charge(&1, &2, cs.lease))
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, response} ->
        {:ok, response}

      {:error, _, err, _} ->
        {:error, err}
    end
  end

  def notify_tenant({:ok, %{tenant: %Tenant{} = tenant} = r, opts}) when length(opts) > 0 do
    from(
      t in Tenant,
      join: o in assoc(t, :leases),
      join: u in assoc(o, :unit),
      join: p in assoc(u, :property),
      left_join: l in assoc(p, :logo_url),
      where: t.id == ^tenant.id,
      select: %{
        first_name: t.first_name,
        last_name: t.last_name,
        email: t.email,
        lease: jsonize_one(o, [:start_date, :end_date]),
        unit: jsonize_one(u, [:number]),
        property: merge(p, %{logo: l.url})
      },
      group_by: [t.id, p.id, l.url]
    )
    |> Repo.one()
    |> AppCountCom.Tenants.new_tenant(opts[:password], opts[:payment])

    {:ok, r}
  end

  def notify_tenant({:ok, t, _}), do: {:ok, t}
  def notify_tenant(e), do: e

  def insert_tenant(tenant_params, {:ok, tenants}) do
    tenant_params
    |> do_insert_tenant()
    |> case do
      {:ok, t} -> {:cont, {:ok, tenants ++ [t]}}
      {:error, e} -> {:halt, {:error, e}}
    end
  end

  def insert_tenant(_tenant_params, {:error, error}), do: {:halt, {:error, error}}

  def do_insert_tenant(tenant_params) do
    %Tenant{}
    |> Tenant.changeset(merge_uuid(tenant_params))
    |> Repo.insert()
  end

  def insert_occupancy(tenant, {:ok, occupancies}, lease_id) do
    %Occupancy{}
    |> Occupancy.changeset(%{"tenant_id" => tenant.id, "lease_id" => lease_id})
    |> Repo.insert()
    |> case do
      {:ok, o} -> {:cont, {:ok, occupancies ++ [o]}}
      {:error, e} -> {:halt, {:error, e}}
    end
  end

  def insert_occupancy(_tenant, {:error, error}, _), do: {:halt, {:error, error}}

  def insert_occupant(occupant, {:ok, _cs}, lease_id) do
    res =
      %Occupant{}
      |> Occupant.changeset(matched_put(occupant, :lease_id, lease_id))
      |> Repo.insert()

    {:cont, res}
  end

  def insert_occupant(_occupant, {:error, error}, _), do: {:halt, {:error, error}}

  def insert_charge(charge_params, {:ok, charges}, lease) do
    %Charge{}
    |> Charge.changeset(
      Map.merge(
        charge_params,
        %{
          "lease_id" => lease.id,
          "next_bill_date" => charge_params["from_date"] || lease.start_date
        }
      )
    )
    |> Repo.insert()
    |> case do
      {:ok, c} -> {:cont, {:ok, charges ++ [c]}}
      {:error, e} -> {:halt, {:error, e}}
    end
  end

  def insert_charge(_charge_params, {:error, error}, _), do: {:halt, {:error, error}}

  def attach_lease_form(multi, nil), do: multi

  def attach_lease_form(multi, application_id) do
    case Repo.get_by(Form, application_id: application_id) do
      nil ->
        multi

      form ->
        Multi.run(
          multi,
          :form,
          fn _repo, cs ->
            Form.changeset(form, %{lease_id: cs.lease.id})
            |> Repo.update()
          end
        )
    end
  end

  def add_application_charges_to_ledger(multi, nil), do: multi

  def add_application_charges_to_ledger(multi, application_id) do
    app = Repo.get(RentApplication, application_id)

    charge_application_fee(multi, app)
    |> charge_admin_fee(app)
  end

  def update_application_payments(multi, nil), do: multi

  def update_application_payments(multi, application_id) do
    multi
    |> Multi.run(
      :application_payments,
      fn _repo, cs ->
        from(
          p in Payment,
          join: r in assoc(p, :receipts),
          where: p.application_id == ^application_id,
          select: p,
          preload: [
            receipts: r
          ]
        )
        |> Repo.all()
        |> Enum.reduce_while(
          {:ok, []},
          fn payment, {:ok, payments} ->
            Enum.each(payment.receipts, &Repo.delete/1)

            Payment.changeset(payment, %{tenant_id: hd(cs.tenants).id, lease_id: cs.lease.id})
            |> Repo.update()
            |> case do
              {:ok, p} -> {:cont, {:ok, payments ++ [p]}}
              e -> {:halt, e}
            end
          end
        )
      end
    )
  end

  defp charge_application_fee(multi, app) do
    Multi.run(
      multi,
      :application_charge,
      fn _repo, cs ->
        # TODO:SCHEMA remove dasmen
        ClientSchema.new("dasmen", %{
          "lease_id" => cs.lease.id,
          "charge_code_id" => Accounting.SpecialAccounts.get_charge_code(:application_fees).id,
          "bill_date" => app.inserted_at,
          "post_month" => Timex.beginning_of_month(app.inserted_at),
          "status" => "manual",
          "amount" => length(cs.occupancies) * 50
        })
        |> Charges.create_charge()
      end
    )
  end

  defp charge_admin_fee(multi, app) do
    Multi.run(
      multi,
      :admin_charge,
      fn _repo, cs ->
        # TODO:SCHEMA remove dasmen
        ClientSchema.new("dasmen", %{
          "lease_id" => cs.lease.id,
          "charge_code_id" => Accounting.SpecialAccounts.get_charge_code(:admin_fees).id,
          "bill_date" => app.inserted_at,
          "post_month" => Timex.beginning_of_month(app.inserted_at),
          "status" => "manual",
          "amount" => 150
        })
        |> Charges.create_charge()
      end
    )
  end

  defp merge_package_pin(params), do: Map.put(params, "package_pin", package_pin())
  defp merge_uuid(params), do: matched_put(params, :uuid, UUID.uuid4())
  defp package_pin(), do: String.slice(to_string(:rand.uniform()), 2..5)

  defp uniformalize_keys(map) do
    for {k, v} <- map, into: %{} do
      {"#{k}", v}
    end
  end

  # UNTESTED
  defp update_bluemoon_lease(admin, lease_id) do
    from(f in Leases.Form, where: f.lease_id == ^lease_id, select: f.id)
    |> Repo.one()
    |> case do
      nil -> nil
      form_id -> Leases.sync_bluemoon_lease(admin, form_id)
    end
  end
end
