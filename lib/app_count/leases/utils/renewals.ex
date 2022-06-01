defmodule AppCount.Leases.Utils.Renewals do
  alias AppCount.Leases
  alias AppCount.Accounting
  alias AppCount.Ledgers
  alias AppCount.Ledgers.Utils.Charges
  alias AppCount.Units
  alias AppCount.Leases.Lease
  alias AppCount.Properties.Unit
  alias AppCount.Properties.Occupancy
  alias AppCount.Repo
  alias Ecto.Multi
  import Ecto.Query
  use AppCount.Decimal
  alias AppCount.Core.ClientSchema

  def new_lease_from_bluemoon_xml(%Lease{} = lease, %BlueMoon.Data.Lease{} = params) do
    assoc =
      from(
        l in Lease,
        join: u in assoc(l, :unit),
        join: t in assoc(l, :tenants),
        preload: [
          unit: u,
          tenants: t
        ],
        where: l.id == ^lease.id
      )
      |> Repo.one()

    unit = Repo.get_by(Unit, number: params.unit, property_id: assoc.unit.property_id)

    lease_params =
      Map.take(params, [:start_date, :end_date])
      |> Map.merge(%{
        admin: lease.renewal_admin,
        unit_id: unit.id,
        bluemoon_lease_id: lease.pending_bluemoon_lease_id,
        bluemoon_signature_id: lease.pending_bluemoon_signature_id
      })

    default_lease_charges =
      from(
        dfl in Units.DefaultLeaseCharge,
        select: %{
          id: dfl.id,
          charge_code_id: dfl.charge_code_id,
          amount: dfl.price
        },
        where: dfl.id in ^lease.pending_default_lease_charges
      )
      |> Repo.all()

    Multi.new()
    |> Multi.insert(:lease, Lease.changeset(%Lease{}, lease_params))
    |> Multi.run(
      :occupancies,
      fn _repo, cs ->
        Enum.reduce_while(
          assoc.tenants,
          {:ok, []},
          fn tenant, {:ok, occupancies} ->
            %Occupancy{}
            |> Occupancy.changeset(%{lease_id: cs.lease.id, tenant_id: tenant.id})
            |> Repo.insert()
            |> case do
              {:ok, occ} -> {:cont, {:ok, occupancies ++ [occ]}}
              e -> {:halt, e}
            end
          end
        )
      end
    )
    |> Multi.run(
      :renewal_ref,
      fn _repo, cs ->
        if lease_params.unit_id == lease.unit_id do
          Lease.changeset(lease, %{renewal_id: cs.lease.id})
          |> Repo.update()
        else
          {:ok, nil}
        end
      end
    )
    |> Multi.run(
      :sec_dep_charge,
      fn _repo, %{lease: l, renewal_ref: r} ->
        if r, do: {:ok, nil}, else: Leases.create_sec_dep_charge(l)
      end
    )
    |> Multi.run(
      :rent_charge,
      fn _repo, cs ->
        %{
          lease_id: cs.lease.id,
          amount: params.rent,
          charge_code_id: Accounting.SpecialAccounts.get_charge_code(:rent).id
        }
        |> AppCount.Properties.create_charge()
      end
    )
    |> Multi.update(
      :remove_pending,
      Lease.changeset(lease, %{pending_bluemoon_signature_id: nil, pending_bluemoon_lease_id: nil})
    )
    |> Multi.run(
      :default_lease_charges,
      fn _repo, %{lease: l} ->
        Enum.reduce_while(
          default_lease_charges,
          {:ok, []},
          fn c, {_, charges} ->
            c
            |> Map.put(:lease_id, l.id)
            |> AppCount.Properties.create_charge()
            |> case do
              {:ok, c} -> {:cont, {:ok, [c | charges]}}
              e -> {:halt, e}
            end
          end
        )
      end
    )
    |> Multi.run(
      :charge_adjustments,
      fn _repo, _cs ->
        prorated_charge_adjustment(lease.id, lease_params.start_date)
      end
    )
    #    |> Multi.run(
    #         :charges,
    #         fn (_repo, %{lease: l}) ->
    #           Enum.reduce_while(
    #             (params["charges"] || []),
    #             {:ok, []},
    #             fn (c, {_, charges}) ->
    #               put_in(c["lease_id"], l.id)
    #               |> AppCount.Properties.create_charge()
    #               |> case do
    #                    {:ok, c} -> {:cont, {:ok, [c | charges]}}
    #                    e -> {:halt, e}
    #                  end
    #             end
    #           )
    #         end
    #       )
    |> Repo.transaction()
  end

  def prorated_charge_adjustment(lease_id, renewal_date) do
    from(
      c in Ledgers.Charge,
      where: c.bill_date >= ^Timex.beginning_of_month(renewal_date),
      where: c.lease_id == ^lease_id,
      where: c.charge_code_id == ^Accounting.SpecialAccounts.get_charge_code(:rent).id,
      where: c.amount > 0,
      select: c.amount
    )
    |> Repo.all()
    |> case do
      [rent_amount] ->
        new_lease_days = Timex.diff(Timex.end_of_month(renewal_date), renewal_date, :days) + 1

        deduct =
          (new_lease_days / Timex.days_in_month(renewal_date) * rent_amount * -1)
          |> Float.round(2)

        # TODO:SCHEMA remove dasmen
        Charges.create_charge(
          ClientSchema.new(
            "dasmen",
            %{
              lease_id: lease_id,
              amount: deduct,
              bill_date: renewal_date,
              status: "charge",
              charge_code_id: Accounting.SpecialAccounts.get_charge_code(:rent).id
            }
          )
        )

      _ ->
        {:ok, []}
    end
  end
end
