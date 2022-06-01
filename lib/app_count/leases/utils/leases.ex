defmodule AppCount.Leases.Utils.Leases do
  alias AppCount.Repo
  alias AppCount.Accounting
  alias AppCount.Ledgers
  alias AppCount.Ledgers.Utils.Charges
  alias AppCount.Leases.Lease
  alias AppCount.Properties.Occupancy
  alias AppCount.Core.LeaseTopic
  alias AppCount.Tenants.TenantRepo
  alias Ecto.Multi
  require Logger
  import Ecto.Query
  alias AppCount.Core.ClientSchema

  def create_lease(%AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    Multi.new()
    |> Multi.insert(:lease, Lease.changeset(%Lease{}, params), prefix: client_schema)
    |> Multi.run(
      :occupancy,
      fn _repo, cs ->
        new_params = merge_lease_id(params, cs.lease)

        %Occupancy{}
        |> Occupancy.changeset(new_params)
        |> Repo.insert(prefix: client_schema)
      end
    )
    |> Multi.run(
      :renewal_ref,
      fn _repo, cs ->
        add_renewal_ref(cs.lease, cs.occupancy)
      end
    )
    |> Multi.run(
      :sec_dep_charge,
      fn _repo, %{lease: l, renewal_ref: r} ->
        unless r, do: create_sec_dep_charge(ClientSchema.new(client_schema, l)), else: {:ok, nil}
      end
    )
    |> Multi.run(
      :charges,
      fn _repo, %{lease: l} ->
        Enum.reduce_while(
          params["charges"] || [],
          {:ok, []},
          fn c, {_, charges} ->
            put_in(c["lease_id"], l.id)
            |> AppCount.Properties.create_charge()
            |> case do
              {:ok, c} -> {:cont, {:ok, [c | charges]}}
              e -> {:halt, e}
            end
          end
        )
      end
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{lease: lease} = result} ->
        publish_lease_created_event(lease.id, tenant_id(params))
        {:ok, result}

      everything_else ->
        everything_else
    end
  end

  def publish_lease_created_event(lease_id, tenant_id, tenant_repo \\ TenantRepo) do
    case tenant_repo.get(tenant_id) do
      %AppCount.Tenants.Tenant{} = tenant ->
        LeaseTopic.created(
          %{lease_id: lease_id, tenant_id: tenant.id},
          __MODULE__
        )

        {:ok, tenant}

      _ ->
        message = "LeaseHolder not found on lease_id: #{lease_id}"
        Logger.error(message)
        {:error, message}
    end
  end

  def update_lease(id, %AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    cs =
      Repo.get(Lease, id, prefix: client_schema)
      |> Lease.changeset(params)

    Multi.new()
    |> Multi.update(:lease, cs, prefix: client_schema)
    |> Multi.run(
      :sec_dep_charge,
      fn _repo, %{lease: l} ->
        if cs.changes[:deposit_amount] do
          create_sec_dep_charge(ClientSchema.new(client_schema, l))
        else
          {:ok, nil}
        end
      end
    )
    |> Repo.transaction()
  end

  def update_leases(lease_ids, %AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    Enum.each(lease_ids, fn lease_id ->
      update_lease(lease_id, %AppCount.Core.ClientSchema{name: client_schema, attrs: params})
    end)
  end

  def add_renewal_ref(lease, occupancy) do
    old_lease_id =
      from(
        l in Lease,
        join: o in assoc(l, :occupancies),
        where: l.unit_id == ^lease.unit_id,
        where: o.tenant_id == ^occupancy.tenant_id,
        where: l.end_date < ^lease.start_date,
        where: is_nil(l.renewal_id),
        select: l.id,
        order_by: [
          desc: l.end_date
        ],
        limit: 1
      )
      |> Repo.one()

    if old_lease_id do
      Repo.get(Lease, old_lease_id)
      |> Lease.changeset(%{renewal_id: lease.id})
      |> Repo.update()
    else
      {:ok, nil}
    end
  end

  def create_sec_dep_charge(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: %{deposit_amount: dep} = lease
      })
      when not is_nil(dep) do
    sec_dep_charge_code_id = Accounting.SpecialAccounts.get_charge_code(:sec_dep_fee).id

    Repo.get_by(Ledgers.Charge, lease_id: lease.id, charge_code_id: sec_dep_charge_code_id)
    |> case do
      nil ->
        ClientSchema.new(client_schema, %{
          amount: dep,
          status: "manual",
          lease_id: lease.id,
          charge_code_id: sec_dep_charge_code_id,
          bill_date: lease.start_date
        })
        |> Charges.create_charge()

      charge ->
        Charges.update_charge(charge.id, ClientSchema.new(client_schema, %{amount: dep}))
    end
  end

  def create_sec_dep_charge(_), do: {:ok, nil}

  def document_url(lease_id) do
    from(
      l in Lease,
      where: l.id == ^lease_id,
      join: d in assoc(l, :document_url),
      select: d.url
    )
    |> Repo.one()
  end

  def delete_lease(admin, lease_id) do
    cond do
      MapSet.member?(admin.roles, "Super Admin") -> delete_lease(lease_id)
      true -> nil
    end
  end

  def lock_lease(id, %{"check" => check_params} = params) do
    lease = Repo.get(Lease, id)
    actual_move_out = params["actual_move_out"] || lease.actual_move_out

    final_charge = %{
      "lease_id" => id,
      "amount" => check_params["amount"],
      "status" => "manual",
      "charge_code_id" => Accounting.SpecialAccounts.get_charge_code(:sec_dep_clearing).id,
      "bill_date" => actual_move_out,
      "admin" => params["admin"],
      "post_month" => Timex.beginning_of_month(AppCount.current_date())
    }

    to_close = find_old_leases(lease, [])

    Multi.new()
    |> Multi.update(:lease, Lease.changeset(lease, %{actual_move_out: actual_move_out}))
    |> Multi.update_all(
      :closings,
      from(l in Lease, where: l.id in ^to_close),
      set: [
        closed: true
      ]
    )
    |> Multi.insert(:charge, Ledgers.Charge.changeset(%Ledgers.Charge{}, final_charge))
    |> Multi.run(
      :check,
      fn _repo, cs ->
        %Accounting.Check{}
        |> Accounting.Check.changeset(Map.put(check_params, "charge_id", cs.charge.id))
        |> Repo.insert()
      end
    )
    |> Repo.transaction()
  end

  defp find_old_leases(nil, list), do: list

  defp find_old_leases(lease, list),
    do: find_old_leases(Repo.get_by(Lease, renewal_id: lease.id), list ++ [lease.id])

  def unlock_lease(lease_id) do
    # TODO:SCHEMA remove dasmen
    result = update_lease(lease_id, ClientSchema.new("dasmen", %{closed: false}))

    from(l in Lease, where: l.renewal_id == ^lease_id, select: l.id)
    |> Repo.one()
    |> case do
      nil -> result
      id -> unlock_lease(id)
    end
  end

  def save_lease_pdf(lease_id) do
    {property_id, signature_id} =
      from(
        l in Lease,
        join: u in assoc(l, :unit),
        select: {u.property_id, l.bluemoon_signature_id},
        where: l.id == ^lease_id
      )
      |> Repo.one()

    AppCount.Leases.Utils.BlueMoon.property_credentials(%{property_id: property_id})
    |> BlueMoon.get_signature_pdf(signature_id)
    |> case do
      {:ok, base64_pdf} ->
        uuid =
          Base.decode64!(base64_pdf)
          |> AppCount.Data.binary_to_upload("lease.pdf", "application/pdf")

        doc = %{"uuid" => uuid}

        Repo.get(Lease, lease_id)
        |> Lease.changeset(%{document: doc})
        |> Repo.update()

      _ ->
        nil
    end
  end

  defp merge_lease_id(%{"tenant_id" => _} = p, lease), do: Map.put(p, "lease_id", lease.id)
  defp merge_lease_id(%{tenant_id: _} = p, lease), do: Map.put(p, :lease_id, lease.id)

  defp tenant_id(%{"tenant_id" => tenant_id}), do: tenant_id
  defp tenant_id(%{tenant_id: tenant_id}), do: tenant_id

  defp delete_lease(lease_id) do
    Repo.get(Lease, lease_id)
    |> Repo.delete()
  end
end
