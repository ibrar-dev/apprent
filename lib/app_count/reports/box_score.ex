defmodule AppCount.Reports.BoxScore do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Admins
  alias AppCount.Repo
  alias AppCount.Ledgers
  alias AppCount.Maintenance.CardItem
  alias AppCount.Properties.Eviction
  alias AppCount.Leases.Lease
  alias AppCount.RentApply.Person
  alias AppCount.Leases.Utils.Leases
  alias AppCount.Prospects.Showing
  alias AppCount.Core.ClientSchema

  ## Per Floor Plan:
  ### Availability
  #### FPNAME | Sq Ft | Avg Rent | Units | Occupied | Vacant Rented | Vacant Unrented | Notice Rented | Notice Unrented | Available | Model | Down | % Occupied | % Occupied w/ non rev | % Leased | % Trend
  #### Total:  | AVG SqFt | Avg Rent | Sum --------------------------------------------------------------------------------------------------------| AVG Percentage --------------------------------------|
  ### Resident Activity
  #### FPName | Units | Move In | Move Out | Notice | ?Rented? | Transfer | MTM | Renewal | Evict
  #### Totals | SUM ----------------------------------------------------------------------------|

  def box_score_report(admin, property_id, start_date, end_date) do
    start_date = Timex.parse!(start_date, "{YYYY}-{D}-{M}")
    end_date = Timex.parse!(end_date, "{YYYY}-{D}-{M}")
    move_in = find_move_in(admin, property_id, start_date, end_date)
    move_out = find_move_out(admin, property_id, start_date, end_date)
    onsite_transfer = onsite_transfer(admin, property_id, start_date, end_date)
    renewal = renewal(admin, property_id, start_date, end_date)
    month = month_to_month(admin, property_id, start_date, end_date)
    evictions = find_evictions(admin, property_id, start_date, end_date)
    tours = find_tours(admin, property_id, start_date, end_date)
    applicants = find_applicants(admin, property_id, start_date, end_date)

    %{
      move_in: move_in,
      move_out: move_out,
      onsite_transfer: onsite_transfer,
      renewal: renewal,
      month: month,
      evictions: evictions,
      tours: tours,
      applicants: applicants
    }
  end

  def rent_charge_query(date) do
    rent_account = AppCount.Accounting.SpecialAccounts.get_account(:rent)
    haprent_account = AppCount.Accounting.SpecialAccounts.get_account(:hap_rent)

    from(
      c in AppCount.Properties.Charge,
      where:
        (c.from_date <= ^date and is_nil(c.to_date)) or
          (is_nil(c.from_date) and c.to_date >= ^date) or
          (is_nil(c.from_date) and is_nil(c.to_date)) or
          (c.from_date <= ^date and c.to_date >= ^date),
      join: a in assoc(c, :account),
      where: c.account_id == ^rent_account.id or c.account_id == ^haprent_account.id,
      select: %{
        id: c.id,
        amount: c.amount,
        lease_id: c.lease_id,
        name: a.name
      }
    )
  end

  def find_move_in(admin, property_id, start_date, end_date) do
    onsite =
      onsite_transfer(admin, property_id, start_date, end_date)
      |> Enum.reduce(
        [],
        fn l, acc ->
          Enum.concat(acc, Enum.map(l.tenants, fn t -> t["id"] end))
        end
      )

    renewals =
      renewal(admin, property_id, start_date, end_date)
      |> Enum.reduce(
        [],
        fn l, acc ->
          Enum.concat(acc, Enum.map(l.tenants, fn t -> t["id"] end))
        end
      )

    from(
      l in Lease,
      join: u in assoc(l, :unit),
      join: p in assoc(u, :property),
      left_join: c in subquery(rent_charge_query(end_date)),
      on: c.lease_id == l.id,
      left_join: f in assoc(u, :floor_plan),
      join: t in assoc(l, :tenants),
      select: %{
        id: l.id,
        property_id: p.id,
        property_name: p.name,
        unit_id: u.id,
        number: u.number,
        floor_plan_id: f.id,
        floor_plan_name: f.name,
        rent_amount: jsonize(c, [:id, :amount, :name]),
        tenants: jsonize(t, [:id, :first_name, :last_name]),
        lease:
          jsonize(
            l,
            [
              :id,
              :start_date,
              :end_date,
              :move_out_date,
              :expected_move_in,
              :actual_move_in,
              :unit_id,
              :notice_date,
              :deposit_amount,
              :actual_move_out,
              :deposit_amount
            ]
          )
      },
      where: p.id in ^Admins.property_ids_for(ClientSchema.new("dasmen", admin)),
      where: l.actual_move_in >= ^start_date and l.actual_move_in <= ^end_date,
      where: t.id not in ^renewals,
      where: t.id not in ^onsite,
      where: p.id == ^property_id,
      distinct: [u.id],
      group_by: [u.id, l.id, p.id, f.id, t.id, c.lease_id],
      order_by: [
        desc: u.id
      ]
    )
    |> Repo.all()
  end

  def find_move_out(admin, property_id, start_date, end_date) do
    evictions =
      from(
        e in Eviction,
        join: l in assoc(e, :lease),
        join: u in assoc(l, :unit),
        join: p in assoc(u, :property),
        select: e.lease_id,
        where: p.id == ^property_id
      )
      |> Repo.all()

    onsite =
      onsite_transfer(admin, property_id, start_date, end_date)
      |> Enum.reduce(
        [],
        fn l, acc ->
          Enum.concat(acc, Enum.map(l.tenants, fn t -> t["id"] end))
        end
      )

    renewals =
      renewal(admin, property_id, start_date, end_date)
      |> Enum.reduce(
        [],
        fn l, acc ->
          Enum.concat(acc, Enum.map(l.tenants, fn t -> t["id"] end))
        end
      )

    from(
      l in Lease,
      join: u in assoc(l, :unit),
      left_join: c in subquery(rent_charge_query(end_date)),
      on: c.lease_id == l.id,
      join: p in assoc(u, :property),
      left_join: f in assoc(u, :floor_plan),
      join: t in assoc(l, :tenants),
      left_join: card in assoc(l, :card),
      left_join: cI in CardItem,
      on: cI.card_id == card.id,
      select: %{
        id: l.id,
        property_id: p.id,
        property_name: p.name,
        unit_id: u.id,
        number: u.number,
        floor_plan_id: f.id,
        floor_plan_name: f.name,
        card_item_id: cI.id,
        card_item: cI.completed_by,
        completed: cI.completed,
        rent_amount: jsonize(c, [:id, :amount, :name]),
        tenants: jsonize(t, [:id, :first_name, :last_name]),
        lease:
          jsonize(
            l,
            [
              :id,
              :start_date,
              :end_date,
              :move_out_date,
              :expected_move_in,
              :actual_move_in,
              :unit_id,
              :notice_date,
              :deposit_amount,
              :actual_move_out,
              :deposit_amount
            ]
          )
      },
      where: p.id in ^Admins.property_ids_for(ClientSchema.new("dasmen", admin)),
      #        where: is_nil(l.renewal_id),
      where: l.actual_move_out >= ^start_date and l.actual_move_out <= ^end_date,
      where: l.id not in ^evictions,
      where: p.id == ^property_id,
      where: t.id not in ^renewals,
      where: t.id not in ^onsite,
      distinct: [u.id],
      group_by: [u.id, p.id, p.name, f.id, l.id, t.id, cI.id, c.lease_id],
      order_by: [
        desc: u.id
      ]
    )
    |> Repo.all()
  end

  def onsite_transfer(_admin, property_id, _start_date, _end_date) do
    curr_leases =
      from(
        l in Lease,
        join: o in assoc(l, :occupancies),
        join: t in assoc(l, :tenants),
        join: u in assoc(l, :unit),
        join: p in assoc(u, :property),
        select: %{
          id: l.id,
          unit_id: l.unit_id,
          tenant_id: o.tenant_id
        },
        #        where: l.actual_move_in >= ^start_date and l.actual_move_in <= ^end_date,
        where: u.property_id == ^property_id
      )

    from(
      l in Lease,
      join: o in assoc(l, :occupancies),
      join: t in assoc(l, :tenants),
      join: u in assoc(l, :unit),
      join: p in assoc(u, :property),
      left_join: f in assoc(u, :floor_plan),
      #      left_join: c in subquery(rent_charge_query(end_date)),
      #      on: c.lease_id == l.id,
      join: cl in subquery(curr_leases),
      on: cl.tenant_id == o.tenant_id,
      select: %{
        id: l.id,
        start_date: l.start_date,
        end_date: l.end_date,
        move_out_date: l.move_out_date,
        expected_move_in: l.expected_move_in,
        actual_move_in: l.actual_move_in,
        unit_id: l.unit_id,
        tenants: jsonize(t, [:id, :first_name, :last_name]),
        notice_date: l.notice_date,
        deposit_amount: l.deposit_amount,
        actual_move_out: l.actual_move_out,
        inserted_at: l.inserted_at,
        property_name: p.name,
        number: u.number,
        floor_plan_id: u.floor_plan_id,
        floor_plan_name: f.name,
        status: u.status,
        address: u.address,
        curr_lease: cl
        #        rent_amount: jsonize(c, [:id, :amount, :name])
      },
      where: cl.id != l.id and cl.unit_id != l.unit_id,
      #      where: u.property_id in ^Admins.property_ids_for(ClientSchema.new("dasmen", admin)),
      where: u.property_id == ^property_id,
      distinct: [u.id],
      order_by: [
        desc: u.id
      ],
      group_by: [l.id, p.id, f.id, u.id, cl.id, cl.unit_id, cl.tenant_id, o.tenant_id]
      #      group_by: [l.id, p.id, f.id, u.id, cl.id, cl.unit_id, cl.tenant_id, o.tenant_id, c.lease_id]
    )
    |> Repo.all()
  end

  def find_renewal_leases(property_id) do
    new_lease =
      from(
        l in Lease,
        select: %{
          id: l.id,
          unit_id: l.unit_id,
          tenant_id: l.tenant_id
        },
        distinct: [l.tenant_id],
        order_by: [
          desc: l.start_date
        ]
      )

    from(
      l in Lease,
      join: nl in subquery(new_lease),
      join: u in assoc(l, :unit),
      join: p in assoc(u, :property),
      on: nl.tenant_id == l.tenant_id,
      select: %{
        id: l.id,
        new_lease_id: nl.id
      },
      where: l.unit_id == nl.unit_id and l.id != nl.id,
      where: is_nil(l.renewal_id),
      where: p.id == ^property_id,
      distinct: [l.tenant_id],
      order_by: [
        desc: l.start_date
      ]
    )
    |> Repo.all()
  end

  def add_renewal_ids(property_id) do
    renewal_ids = find_renewal_leases(property_id)
    Enum.each(renewal_ids, fn x -> Leases.update_lease(x.id, %{renewal_id: x.new_lease_id}) end)
  end

  #    dont use for now
  #    def find_all_renewal_ids(property_id) do
  #      now = DateTime.utc_now()
  #      from(
  #        l in Lease,
  #        join: u in assoc(l, :unit),
  #        join: p in assoc(u, :property),
  #        select: %{
  #          id: l.id,
  #          renewal_id: l.renewal_id,
  #          end_date: l.end_date
  #        },
  #        where: not is_nil(l.renewal_id),
  #        where: p.id == ^property_id,
  #        where: is_nil(l.actual_move_out),
  #        where: l.end_date <= ^now
  #      )
  #      |> Repo.all
  #    end
  #
  #    def update_all_lease(property_id) do
  #      lease_ids = find_all_renewal_ids(property_id)
  #      Enum.each(lease_ids, fn(l) ->
  #        update_lease(l.id, %{actual_move_out: l.end_date})
  #        update_lease(l.renewal_id, %{actual_move_in: l.end_date})
  #      end)
  #    end
  #
  #    def update_lease(id, params) do
  #      Repo.get(Lease, id)
  #        |> Lease.changeset(params)
  #        |> Repo.update
  #    end

  def renewal(admin, property_id, start_date, end_date) do
    old_leases =
      from(
        ol in Lease,
        select: %{
          id: ol.id,
          renewal_id: ol.renewal_id
        },
        where: not is_nil(ol.renewal_id)
      )

    # temp
    lease_time =
      from(
        l in Lease,
        join: o in assoc(l, :occupancies),
        join: u in assoc(l, :unit),
        join: p in assoc(u, :property),
        on: p.id == u.property_id,
        select: %{
          id: l.id,
          start_date: l.start_date,
          end_date: l.end_date,
          move_out_date: l.move_out_date,
          expected_move_in: l.expected_move_in,
          actual_move_in: l.actual_move_in,
          unit_id: l.unit_id,
          number: u.number,
          tenant_id: o.tenant_id,
          notice_date: l.notice_date,
          deposit_amount: l.deposit_amount,
          actual_move_out: l.actual_move_out,
          inserted_at: l.inserted_at
        },
        where: l.actual_move_in >= ^start_date and l.actual_move_in <= ^end_date,
        where: u.property_id == ^property_id
      )

    temp =
      from(
        l in Lease,
        join: t in assoc(l, :tenants),
        left_join: c in subquery(rent_charge_query(end_date)),
        on: c.lease_id == l.id,
        join: u in assoc(l, :unit),
        join: p in assoc(u, :property),
        join: i in subquery(lease_time),
        on: i.tenant_id == t.id,
        left_join: f in assoc(u, :floor_plan),
        select: %{
          id: l.id,
          unit_id: u.id,
          number: u.number,
          property_id: p.id,
          floor_plan_id: f.id,
          floor_plan_name: f.name,
          status: u.status,
          rent_amount: jsonize(c, [:id, :amount, :name]),
          property_name: p.name,
          tenants: jsonize(t, [:id, :first_name, :last_name]),
          lease:
            jsonize(
              i,
              [
                :id,
                :start_date,
                :end_date,
                :move_out_date,
                :expected_move_in,
                :actual_move_in,
                :unit_id,
                :notice_date,
                :deposit_amount,
                :actual_move_out,
                :deposit_amount
              ]
            )
        },
        where: u.property_id in ^admin.property_ids,
        where: i.id != l.id and i.unit_id == l.unit_id,
        where: u.property_id == ^property_id,
        group_by: [l.id, u.id, p.id, c.lease_id, f.id, t.id],
        distinct: [l.id],
        order_by: [
          desc: l.start_date
        ]
      )
      |> Repo.all(prefix: admin.client_schema)

    # temp above is for old lease without renewal ids
    future =
      from(
        l in Lease,
        right_join: ol in subquery(old_leases),
        on: ol.renewal_id == l.id,
        left_join: c in subquery(rent_charge_query(end_date)),
        on: c.lease_id == l.id,
        join: u in assoc(l, :unit),
        join: p in assoc(u, :property),
        left_join: f in assoc(u, :floor_plan),
        join: t in assoc(l, :tenants),
        select: %{
          id: l.id,
          unit_id: u.id,
          number: u.number,
          area: u.area,
          property_id: p.id,
          floor_plan_id: f.id,
          floor_plan_name: f.name,
          status: u.status,
          rent_amount: jsonize(c, [:id, :amount, :name]),
          property_name: p.name,
          tenants: jsonize(t, [:id, :first_name, :last_name]),
          start_date: l.start_date,
          lease:
            jsonize(
              l,
              [
                :id,
                :start_date,
                :end_date,
                :move_out_date,
                :expected_move_in,
                :actual_move_in,
                :unit_id,
                :notice_date,
                :deposit_amount,
                :actual_move_out,
                :deposit_amount
              ]
            )
        },
        where: u.property_id in ^admin.property_ids,
        where: l.start_date >= ^start_date and l.start_date <= ^end_date,
        where: u.property_id == ^property_id,
        group_by: [l.id, l.start_date, u.id, p.id, c.lease_id, f.id, t.id],
        distinct: [t.id],
        order_by: [
          desc: l.start_date
        ]
      )
      |> Repo.all(prefix: admin.client_schema)

    list = Enum.concat(temp, future)
    new_list = Enum.uniq_by(list, fn x -> x.unit_id end)
    Enum.sort(new_list, fn x, y -> x.unit_id < y.unit_id end)
  end

  def month_to_month(admin, property_id, start_date, end_date) do
    lease_time =
      from(
        l in Lease,
        join: o in assoc(l, :occupancies),
        left_join: c in subquery(rent_charge_query(end_date)),
        on: c.lease_id == l.id,
        join: u in assoc(l, :unit),
        on: u.id == l.unit_id,
        join: p in assoc(u, :property),
        on: p.id == u.property_id,
        select: %{
          id: l.id,
          start_date: l.start_date,
          end_date: l.end_date,
          move_out_date: l.move_out_date,
          expected_move_in: l.expected_move_in,
          actual_move_in: l.actual_move_in,
          unit_id: l.unit_id,
          tenant_id: o.tenant_id,
          notice_date: l.notice_date,
          deposit_amount: l.deposit_amount,
          actual_move_out: l.actual_move_out,
          inserted_at: l.inserted_at,
          rent_amount: jsonize(c, [:id, :amount, :name])
        },
        where: l.end_date >= ^start_date and l.end_date <= ^end_date,
        where: u.property_id == ^property_id,
        where: is_nil(l.actual_move_out),
        where: not is_nil(l.actual_move_in),
        group_by: [l.id, o.tenant_id, c.lease_id]
      )

    from(
      l in Lease,
      join: u in assoc(l, :unit),
      join: p in assoc(u, :property),
      join: i in subquery(lease_time),
      on: i.id == l.id,
      left_join: f in assoc(u, :floor_plan),
      join: ten in assoc(l, :tenants),
      select: %{
        id: l.id,
        start_date: l.start_date,
        end_date: l.end_date,
        move_out_date: l.move_out_date,
        expected_move_in: l.expected_move_in,
        actual_move_in: l.actual_move_in,
        unit_id: l.unit_id,
        tenant_id: ten.id,
        first_name: ten.first_name,
        last_name: ten.last_name,
        notice_date: l.notice_date,
        deposit_amount: l.deposit_amount,
        actual_move_out: l.actual_move_out,
        inserted_at: l.inserted_at,
        property_id: p.id,
        property_name: p.name,
        number: u.number,
        area: u.area,
        floor_plan_id: u.floor_plan_id,
        floor_plan_name: f.name,
        status: u.status,
        address: u.address,
        lease: i
      },
      distinct: [l.unit_id],
      order_by: [
        desc: l.inserted_at
      ],
      where: u.property_id in ^admin.property_ids,
      where: u.property_id == ^property_id
    )
    |> Repo.all(prefix: admin.client_schema)
  end

  def find_evictions(admin, property_id, start_date, end_date) do
    from(
      e in Eviction,
      join: l in assoc(e, :lease),
      join: u in assoc(l, :unit),
      join: p in assoc(u, :property),
      left_join: f in assoc(u, :floor_plan),
      join: t in assoc(l, :tenants),
      select: %{
        id: e.id,
        evict_date: e.file_date,
        floor_plan_id: u.floor_plan_id,
        floor_plan_name: f.name,
        lease_id: l.id,
        tenant_id: t.id,
        first_name: t.first_name,
        last_name: t.last_name,
        start_date: l.start_date,
        end_date: l.end_date,
        move_out_date: l.move_out_date,
        expected_move_in: l.expected_move_in,
        actual_move_in: l.actual_move_in,
        actual_move_out: l.actual_move_out,
        notice_date: l.notice_date,
        deposit_amount: l.deposit_amount,
        number: u.number,
        area: u.area,
        unit_id: u.id,
        status: u.status,
        address: u.address,
        property_id: p.id,
        property_name: p.name
      },
      where: e.file_date >= ^start_date and e.file_date <= ^end_date,
      where: u.property_id in ^admin.property_ids,
      where: u.property_id == ^property_id
    )
    |> Repo.all(prefix: admin.client_schema)
  end

  def find_tours(admin, property_id, start_date, end_date) do
    from(
      s in Showing,
      left_join: ps in assoc(s, :prospect),
      select: %{
        id: s.id,
        date: s.date,
        prospect_id: s.prospect_id,
        contact_date: ps.contact_date,
        contact_type: ps.contact_type,
        contact_result: ps.contact_result,
        move_in: ps.move_in,
        unit_type: ps.unit_type,
        phone: ps.phone,
        start_time: s.start_time,
        end_time: s.end_time,
        name: ps.name
      },
      where: s.date <= ^end_date and s.date >= ^start_date,
      where: s.property_id in ^admin.property_ids,
      where: s.property_id == ^property_id
    )
    |> Repo.all(prefix: admin.client_schema)
  end

  def find_applicants_report(admin, property_id, start_date, end_date) do
    start_date = Timex.parse!(start_date, "{YYYY}-{D}-{M}")
    end_date = Timex.parse!(end_date, "{YYYY}-{D}-{M}")
    find_payments(admin, property_id, start_date, end_date)
  end

  def find_applicants_subquery(property_id) do
    from(
      pers in Person,
      join: a in assoc(pers, :application),
      join: p in assoc(a, :payments),
      select: %{
        id: pers.id,
        applicant_id: a.id,
        name: pers.full_name,
        email: pers.email,
        payment_id: p.id
      },
      where: a.property_id == ^property_id
    )
  end

  def find_payments(_admin, property_id, start_date, end_date) do
    from(
      p in Ledgers.Payment,
      join: pr in assoc(p, :property),
      on: p.property_id == pr.id,
      left_join: a in subquery(find_applicants_subquery(property_id)),
      on: a.applicant_id == p.application_id,
      select: %{
        id: p.id,
        transaction_id: p.transaction_id,
        property_id: pr.id,
        post_month: p.post_month,
        amount: p.amount,
        response: p.response,
        description: p.description,
        applicant: jsonize(a, [:id, :name, :email]),
        date: p.inserted_at
      },
      where: p.inserted_at >= ^start_date and p.inserted_at <= ^end_date,
      where: p.property_id == ^property_id,
      where: not is_nil(p.application_id),
      group_by: [p.id, pr.id],
      order_by: :inserted_at,
      distinct: [p.id]
    )
    |> Repo.all()
  end

  def find_applicants(admin, property_id, start_date, end_date) do
    from(
      pers in Person,
      join: a in assoc(pers, :application),
      join: p in assoc(a, :property),
      left_join: ps in assoc(a, :prospect),
      select: %{
        id: pers.id,
        name: pers.full_name,
        email: pers.email,
        home_phone: pers.home_phone,
        work_phone: pers.work_phone,
        cell_phone: pers.cell_phone,
        prospect_id: ps.id,
        contact_date: ps.contact_date,
        contact_type: ps.contact_type,
        contact_result: ps.contact_result,
        unit_type: ps.unit_type,
        dob: pers.dob,
        application_id: a.id,
        property_id: p.id,
        property_name: p.name,
        application_submitted: a.inserted_at,
        status: a.status
      },
      where: pers.status == "Lease Holder",
      where: a.inserted_at >= ^start_date and a.inserted_at <= ^end_date,
      where: p.id in ^Admins.property_ids_for(ClientSchema.new("dasmen", admin)),
      where: p.id == ^property_id
    )
    |> Repo.all()
  end
end
