defmodule AppCount.Reports.DailyDeposit do
  import Ecto.Query
  alias AppCount.Ledgers.Payment
  alias AppCount.Admins
  alias AppCount.Repo
  alias AppCount.Core.ClientSchema

  def daily_deposit(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin
        },
        property_id,
        date \\ nil
      ) do
    new_date =
      cond do
        is_nil(date) ->
          AppCount.current_time()
          |> Timex.end_of_day()

        true ->
          Timex.parse!(date, "{YYYY}-{0M}-{D}")
          |> Timex.end_of_day()
      end

    cond do
      Admins.has_permission?(ClientSchema.new(client_schema, admin), property_id) ->
        %{
          daily: get_payments(property_id, Timex.beginning_of_day(new_date), new_date),
          mtd: get_payments(property_id, Timex.beginning_of_month(new_date), new_date),
          down_reno_units: get_units(property_id),
          open_work_orders:
            AppCount.Reports.MaintenanceReport.get_open_orders(
              ClientSchema.new(client_schema, property_id),
              nil
            ),
          tours: get_tours(property_id, Timex.beginning_of_day(new_date), new_date),
          wtd_tours: get_tours(property_id, Timex.beginning_of_week(new_date), new_date),
          apps: get_applications(property_id, Timex.beginning_of_day(new_date), new_date),
          wtd_apps: get_applications(property_id, Timex.beginning_of_week(new_date), new_date),
          declined_apps:
            get_declined_apps(property_id, Timex.beginning_of_day(new_date), new_date),
          wtd_declined_apps:
            get_declined_apps(property_id, Timex.beginning_of_week(new_date), new_date),
          move_ins: get_move_ins(property_id, Timex.beginning_of_day(new_date), new_date),
          wtd_move_ins: get_move_ins(property_id, Timex.beginning_of_week(new_date), new_date),
          move_outs: get_move_outs(property_id, Timex.beginning_of_day(new_date), new_date),
          wtd_move_outs: get_move_outs(property_id, Timex.beginning_of_week(new_date), new_date),
          ntv: get_ntv(property_id, Timex.beginning_of_day(new_date), new_date),
          wtd_ntv: get_ntv(property_id, Timex.beginning_of_week(new_date), new_date),
          new_leases: get_new_leases(property_id, Timex.beginning_of_day(new_date), new_date),
          wtd_new_leases:
            get_new_leases(property_id, Timex.beginning_of_week(new_date), new_date),
          units_min:
            AppCount.Properties.Utils.Reports.list_units_min(
              ClientSchema.new(client_schema, [property_id]),
              new_date
            ),
          occupied_units:
            AppCount.Properties.Utils.Reports.occupied_units([property_id], new_date),
          available_units:
            AppCount.Properties.Utils.Units.list_rentable(
              ClientSchema.new(client_schema, [property_id])
            ),
          trend: AppCount.Properties.Utils.Calculations.calculate_trend_multiple([property_id])
        }

      true ->
        nil
    end
  end

  def get_payments(property_id, start_date, end_date) do
    from(
      p in Payment,
      left_join: t in assoc(p, :tenant),
      where: p.property_id == ^property_id,
      where: p.inserted_at <= ^end_date and p.inserted_at >= ^start_date,
      where: p.status == "cleared",
      select: sum(p.amount)
    )
    |> Repo.one()
  end

  defp get_units(property_id) do
    from(
      u in AppCount.Properties.Unit,
      where: u.property_id == ^property_id and u.status in ["DOWN", "RENO"],
      select: %{
        id: u.id,
        status: u.status
      }
    )
    |> Repo.all()
  end

  ## NOT IN USE YET, BUT IM SURE SOMEONE WILL CLAIM ITS A BUG SOON AND ASK FOR IT ##
  #  defp get_payments_full(property_id, start_date, end_date) do
  #    from(
  #      p in Payment,
  #      left_join: t in assoc(p, :tenant),
  #      where: p.property_id == ^property_id,
  #      where: p.inserted_at <= ^end_date and p.inserted_at >= ^start_date,
  #      select: %{
  #        id: p.id,
  #        amount: p.amount,
  #        source: p.source,
  #        description: p.description,
  #        payer: p.payer,
  #        surcharge: p.surcharge,
  #        tenant: %{
  #          id: p.tenant_id,
  #          name: t.last_name
  #        },
  #        response: p.response
  #      }
  #    )
  #    |> Repo.one
  #  end
  ##  ##

  defp get_tours(property_id, start_date, end_date) do
    from(
      s in AppCount.Prospects.Showing,
      join: p in assoc(s, :prospect),
      where: p.property_id == ^property_id,
      where: s.date <= ^end_date and s.date >= ^start_date,
      select: count(s.id)
    )
    |> Repo.one()
  end

  defp app_query(property_id) do
    from(
      p in AppCount.RentApply.RentApplication,
      where: p.property_id == ^property_id,
      select: count(p.id)
    )
  end

  defp get_applications(property_id, start_date, end_date) do
    app_query(property_id)
    |> where([p], p.inserted_at <= ^end_date and p.inserted_at >= ^start_date)
    |> where([p], is_nil(p.declined_on) or p.declined_on > ^end_date)
    |> Repo.one()
  end

  defp get_declined_apps(property_id, start_date, end_date) do
    app_query(property_id)
    |> where([p], p.declined_on <= ^end_date and p.declined_on >= ^start_date)
    |> Repo.one()
  end

  defp lease_query(property_id) do
    from(
      l in AppCount.Leases.Lease,
      join: u in assoc(l, :unit),
      where: u.property_id == ^property_id,
      select: count(l.id)
    )
  end

  defp get_move_ins(property_id, start_date, end_date) do
    lease_query(property_id)
    |> where([l], l.actual_move_in <= ^end_date and l.actual_move_in >= ^start_date)
    |> Repo.one()
  end

  defp get_ntv(property_id, start_date, end_date) do
    lease_query(property_id)
    |> where([l], l.notice_date <= ^end_date and l.notice_date >= ^start_date)
    |> Repo.one()
  end

  defp get_move_outs(property_id, start_date, end_date) do
    lease_query(property_id)
    |> where([l], l.actual_move_out <= ^end_date and l.actual_move_out >= ^start_date)
    |> Repo.one()
  end

  defp get_new_leases(property_id, start_date, end_date) do
    lease_query(property_id)
    |> where([l], l.inserted_at <= ^end_date and l.inserted_at >= ^start_date)
    |> Repo.one()
  end
end
