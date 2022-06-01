defmodule AppCount.Properties.Utils.Reports do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Repo
  alias AppCount.Maintenance.Utils.Orders
  alias AppCount.Maintenance.Utils.Cards
  alias AppCount.Maintenance.Utils.Parts
  alias AppCount.Properties.Utils.Units
  alias AppCount.Properties.Utils.Alerts
  alias AppCount.Properties.Utils.Calculations
  alias AppCount.Prospects.Showing
  alias AppCount.Properties.Unit
  alias AppCount.Properties.Package
  alias AppCount.Leases.Lease
  alias AppCount.Reports.Queries
  alias AppCount.Core.ClientSchema

  def property_report(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin
        },
        _date \\ nil
      ) do
    property_ids = admin.property_ids

    today =
      AppCount.current_time() |> Timex.beginning_of_day() |> Timex.format!("%Y-%m-%d", :strftime)

    %{
      resident_info: %{
        move_ins: move_ins(property_ids, today),
        move_outs: move_outs(property_ids, today),
        expiring_leases: expiring_leases(property_ids, today),
        on_notice: on_notice(property_ids, today),
        todays_showings: todays_showings(property_ids, today)
      },
      maintenance_info: %{
        currently_open: Orders.open_order_query(ClientSchema.new(client_schema, property_ids)),
        currently_on_hold:
          Orders.order_query_modular(
            %AppCount.Core.ClientSchema{
              name: client_schema,
              attrs: property_ids
            },
            "on_hold"
          ),
        currently_in_progress:
          Orders.order_query_modular(
            %AppCount.Core.ClientSchema{
              name: client_schema,
              attrs: property_ids
            },
            "in_progress"
          ),
        todays_card_items:
          Cards.get_card_items_by_date(
            %AppCount.Core.ClientSchema{
              name: client_schema,
              attrs: property_ids
            },
            today
          ),
        pending_and_ordered_parts:
          Parts.list_parts_for_dashboard(%AppCount.Core.ClientSchema{
            name: client_schema,
            attrs: property_ids
          }),
        not_yet_inspected_units: not_yet_inspected_units(property_ids)
      },
      property_info: %{
        units:
          list_units_min(
            %AppCount.Core.ClientSchema{
              name: client_schema,
              attrs: property_ids
            },
            today
          ),
        occupied_units: Calculations.occupied_units(property_ids, today),
        model_units: model_units(property_ids, today),
        available_units:
          Units.list_rentable(%AppCount.Core.ClientSchema{
            name: client_schema,
            attrs: property_ids
          }),
        uncollected_packages: uncollected_packages(property_ids),
        preleased_units: preleased_units(property_ids, today),
        #        delinquency: AppCount.Reports.Delinquency.dashboard_dq(property_ids),
        calculations: Calculations.property_calculations(property_ids, AppCount.current_date())
      },
      alerts: %{
        no_charge_leases: Alerts.leases_with_no_charges(property_ids),
        past_expected_move_out: Alerts.past_expected_move_out(property_ids),
        floorplans_with_no_default_charges:
          Alerts.floorplans_with_no_default_charges(property_ids)
      }
    }
  end

  def specific_property_report(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: property_ids
      }) do
    today = AppCount.current_time() |> Timex.format!("%Y-%m-%d", :strftime)

    %{
      resident_info: %{
        move_ins: move_ins(property_ids, today),
        move_outs: move_outs(property_ids, today),
        expiring_leases: expiring_leases(property_ids, today),
        on_notice: on_notice(property_ids, today),
        todays_showings: todays_showings(property_ids, today)
      },
      maintenance_info: %{
        currently_open:
          Orders.open_order_query(%AppCount.Core.ClientSchema{
            name: client_schema,
            attrs: property_ids
          }),
        currently_on_hold:
          Orders.order_query_modular(
            %AppCount.Core.ClientSchema{
              name: client_schema,
              attrs: property_ids
            },
            "on_hold"
          ),
        currently_in_progress:
          Orders.order_query_modular(
            %AppCount.Core.ClientSchema{
              name: client_schema,
              attrs: property_ids
            },
            "in_progress"
          ),
        todays_card_items:
          Cards.get_card_items_by_date(
            %AppCount.Core.ClientSchema{
              name: client_schema,
              attrs: property_ids
            },
            today
          ),
        pending_and_ordered_parts:
          Parts.list_parts_for_dashboard(%AppCount.Core.ClientSchema{
            name: client_schema,
            attrs: property_ids
          })
      },
      property_info: %{
        units:
          list_units_min(
            %AppCount.Core.ClientSchema{
              name: client_schema,
              attrs: property_ids
            },
            today
          ),
        occupied_units: Calculations.occupied_units(property_ids, today),
        model_units: model_units(property_ids, today),
        available_units:
          Units.list_rentable(%AppCount.Core.ClientSchema{
            name: client_schema,
            attrs: property_ids
          }),
        uncollected_packages: uncollected_packages(property_ids),
        preleased_units: preleased_units(property_ids, today),
        #        delinquency: AppCount.Reports.Delinquency.dashboard_dq(property_ids),
        calculations: Calculations.property_calculations(property_ids, AppCount.current_date())
      },
      alerts: %{
        no_charge_leases: Alerts.leases_with_no_charges(property_ids),
        past_expected_move_out: Alerts.past_expected_move_out(property_ids),
        floorplans_with_no_default_charges:
          Alerts.floorplans_with_no_default_charges(property_ids)
      }
    }
  end

  # Returns a list of leases that have an expected move in date of today. it may be worth switching this to also show units that do not have an actual move in date updated, similar to the move out function
  defp move_ins(property_ids, date) do
    from(
      l in Lease,
      join: u in assoc(l, :unit),
      join: p in assoc(u, :property),
      join: t in assoc(l, :tenants),
      where:
        l.expected_move_in == ^date and is_nil(l.actual_move_in) and
          u.property_id in ^property_ids,
      select: %{
        id: l.id,
        start_date: l.start_date,
        expected_move_in: l.expected_move_in,
        actual_move_in: l.actual_move_in,
        tenant: %{
          id: t.id,
          name: fragment("? || ' ' || ?", t.first_name, t.last_name),
          email: t.email
        },
        unit: %{
          id: u.id,
          number: u.number,
          property: %{
            id: p.id,
            name: p.name
          }
        }
      },
      distinct: l.id,
      group_by: [l.id, p.id, u.id, t.id]
    )
    |> Repo.all()
  end

  # Returns a list of leases that the move out date is in the past and the actual_move_out date has not been updated
  defp move_outs(property_ids, date) do
    from(
      l in Lease,
      join: u in assoc(l, :unit),
      join: p in assoc(u, :property),
      join: t in assoc(l, :tenants),
      where:
        l.move_out_date <= ^date and is_nil(l.actual_move_out) and u.property_id in ^property_ids,
      select: %{
        id: l.id,
        start_date: l.start_date,
        end_date: l.end_date,
        move_out_date: l.move_out_date,
        notice_date: l.notice_date,
        actual_move_out: l.actual_move_out,
        tenant: %{
          id: t.id,
          name: fragment("? || ' ' || ?", t.first_name, t.last_name),
          email: t.email
        },
        unit: %{
          id: u.id,
          number: u.number,
          property: %{
            id: p.id,
            name: p.name
          }
        }
      },
      distinct: l.id,
      group_by: [l.id, p.id, u.id, t.id]
    )
    |> Repo.all()
  end

  # Returns a list of leases that end_date is less than 120 days in the future (and in the future) and actual_move_out has not been updated
  def expiring_leases(property_ids, date) do
    expiring_date = AppCount.current_time() |> Timex.shift(days: 120)

    from(
      l in Lease,
      join: u in assoc(l, :unit),
      join: p in assoc(u, :property),
      join: t in assoc(l, :tenants),
      left_join: fp in assoc(u, :floor_plan),
      left_join: c in assoc(l, :charges),
      left_join: cc in assoc(c, :charge_code),
      where:
        l.end_date < ^expiring_date and is_nil(l.actual_move_out) and l.end_date > ^date and
          is_nil(l.renewal_id) and
          u.property_id in ^property_ids,
      select: %{
        id: l.id,
        end_date: l.end_date,
        move_out_date: l.move_out_date,
        actual_move_out: l.actual_move_out,
        charges: jsonize(c, [:id, :amount, {:name, cc.name}]),
        tenant: %{
          id: t.id,
          name: fragment("? || ' ' || ?", t.first_name, t.last_name),
          email: t.email
        },
        unit: %{
          id: u.id,
          number: u.number,
          floor_plan: fp.name,
          property: %{
            id: p.id,
            name: p.name
          }
        }
      },
      group_by: [l.id, u.id, p.id, t.id, fp.id]
    )
    |> Repo.all()
  end

  def on_notice(property_ids, date) do
    from(
      l in Lease,
      join: u in assoc(l, :unit),
      join: p in assoc(u, :property),
      join: t in assoc(l, :tenants),
      left_join: r in assoc(l, :move_out_reason),
      where:
        l.notice_date < ^date and is_nil(l.actual_move_out) and u.property_id in ^property_ids,
      select: %{
        id: l.id,
        end_date: l.end_date,
        notice_date: l.notice_date,
        move_out_date: l.move_out_date,
        move_out_reason: r.name,
        tenant: %{
          id: t.id,
          name: t.last_name,
          #          name: fragment("? || ' ' || ?", t.first_name, t.last_name),
          email: t.email
        },
        unit: %{
          id: u.id,
          number: u.number,
          property: %{
            id: p.id,
            name: p.name
          }
        }
      },
      order_by: [asc: l.move_out_date]
    )
    |> Repo.all()
  end

  def list_units_min(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: property_ids
        },
        _date
      ) do
    #    date = AppCount.current_date()

    from(
      u in Unit,
      join: p in assoc(u, :property),
      where: p.id in ^property_ids,
      select: %{
        id: u.id,
        property_id: p.id,
        property_name: p.name,
        number: u.number
      },
      distinct: u.id
    )
    |> Repo.all(prefix: client_schema)
  end

  def model_units(property_ids, _date) do
    from(
      u in Unit,
      where: u.status == "MODEL",
      where: u.property_id in ^property_ids,
      select: %{
        id: u.id,
        number: u.number
      }
    )
    |> Repo.all()
  end

  def todays_showings(property_ids, date) do
    from(
      s in Showing,
      join: p in assoc(s, :prospect),
      join: pro in assoc(s, :property),
      where: s.property_id in ^property_ids and s.date == ^date,
      select: %{
        id: s.id,
        start_time: s.start_time,
        prospect: p.name,
        property_id: pro.id,
        property: pro.name
      }
    )
    |> Repo.all()
  end

  def uncollected_packages(property_ids) do
    from(
      p in Package,
      join: u in assoc(p, :unit),
      join: pro in assoc(u, :property),
      where: p.status == "Pending" and pro.id in ^property_ids,
      select: %{
        id: p.id,
        carrier: p.carrier,
        name: p.name,
        unit: %{
          id: u.id,
          number: u.number
        },
        property: %{
          id: p.id,
          name: p.name
        }
      }
    )
    |> Repo.all()
  end

  def not_yet_inspected_units(property_ids) do
    from(
      u in Unit,
      join: p in assoc(u, :property),
      join: l in assoc(u, :leases),
      left_join: c in assoc(u, :cards),
      where: u.property_id in ^property_ids,
      where: not is_nil(l.actual_move_out),
      where: is_nil(l.renewal_id),
      having: count(l.id, :distinct) > count(c.id, :distinct),
      select: %{
        id: u.id,
        unit: u.number,
        property: p.name,
        lease_end: max(l.end_date),
        move_out: max(l.actual_move_out)
      },
      group_by: [u.id, p.id]
    )
    |> Repo.all()
  end

  def preleased_units(property_ids, _date) do
    date = AppCount.current_date()

    from(
      u in Unit,
      join: t in assoc(u, :tenancies),
      join: s in subquery(Queries.full_unit_status(property_ids, date)),
      on: s.id == u.id,
      join: p in assoc(u, :property),
      where: t.start_date >= ^date and is_nil(t.actual_move_in),
      select: %{
        id: u.id,
        unit: u.number,
        status: s.status,
        property_id: p.id,
        property: p.name,
        start_date: t.start_date
      }
    )
    |> Repo.all()
  end

  def occupied_units(property_ids, _date), do: Calculations.occupied_units(property_ids)
end
