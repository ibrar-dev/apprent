defmodule AppCount.Reports.AMEReport do
  import Ecto.Query
  import AppCount.Decimal
  alias AppCount.Admins
  alias AppCount.Repo
  alias AppCount.Leases.Lease
  alias AppCount.Ledgers.Charge
  use AppCount.Decimal
  alias AppCount.Core.ClientSchema

  def get_move_ins(admin, property_id, start_date, end_date) do
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))

    from(
      l in Lease,
      join: u in assoc(l, :unit),
      where: u.property_id == ^property_id and u.property_id in ^property_ids,
      where: l.actual_move_in <= ^end_date and l.actual_move_in >= ^start_date,
      select: count(l.id)
    )
    |> Repo.one()
  end

  def get_move_outs(admin, property_id, start_date, end_date) do
    property_ids = Admins.property_ids_for(ClientSchema.new("dasmen", admin))

    from(
      l in Lease,
      join: u in assoc(l, :unit),
      where: u.property_id == ^property_id and u.property_id in ^property_ids,
      where: l.actual_move_out <= ^end_date and l.actual_move_out >= ^start_date,
      select: count(l.id)
    )
    |> Repo.one()
  end

  def calculate_delinquency(admin, property_id, start_date, end_date) do
    ## Add Up all the charges and add up all the receipts and spit out percentages

    totals =
      from(
        c in Charge,
        left_join: r in assoc(c, :receipts),
        on:
          c.id == r.charge_id and (is_nil(r.stop_date) or r.stop_date > ^end_date) and
            (is_nil(r.start_date) or r.start_date <= ^end_date),
        join: l in assoc(c, :lease),
        join: u in assoc(l, :unit),
        where: u.property_id == ^property_id and u.property_id in ^admin.property_ids,
        where: c.bill_date <= ^end_date and c.bill_date >= ^start_date,
        where: is_nil(c.reversal_id),
        select: %{
          id: c.id,
          amount: c.amount,
          receipts: sum(r.amount)
        },
        group_by: [c.id]
      )
      |> Repo.all()

    charges = Enum.reduce(totals, 0.00, fn x, acc -> x.amount + acc end)
    receipts = Enum.reduce(totals, 0.00, fn x, acc -> x.receipts + acc end)

    (100 - receipts / charges * 100)
    |> Kernel.round()
  end

  #  def calculate_trend(admin, property_id, date) do
  #    ## Figure out how many units were available as of date and spit out percentage based on total units for that property
  #  end
end
