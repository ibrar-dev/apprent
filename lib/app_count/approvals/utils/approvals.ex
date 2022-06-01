defmodule AppCount.Approvals.Utils.Approvals do
  import AppCount.EctoExtensions
  import Ecto.Query
  alias Ecto.Multi
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Approvals
  alias AppCount.Approvals.Approval
  alias AppCount.Approvals.ApprovalLog
  alias AppCount.Approvals.ApprovalAttachment
  alias AppCount.Approvals.ApprovalNote
  alias AppCount.Approvals.ApprovalCost
  alias AppCount.Approvals.ApprovalRepo
  alias AppCount.Core.ClientSchema

  # create approval to iterate over items in additional location drop down
  def create_approval(%{"addtlProperty" => additional_properties} = params)
      when not is_nil(additional_properties) do
    new_params = Map.delete(params, "addtlProperty")

    case create_approval(new_params) do
      {:ok, approval} ->
        Enum.each(additional_properties, fn id ->
          create_approval(Map.merge(new_params, %{"property_id" => id}))
        end)

        {:ok, approval}

      error ->
        error
    end
  end

  def create_approval(params, client_schema) do
    new_params = generate_num(params)

    Multi.new()
    |> Multi.insert(:approval, Approval.changeset(%Approval{}, new_params))
    |> process_amounts(params["costs"])
    |> create_log(params["approval_logs"])
    |> attach_attachments(params["attachments"])
    |> Repo.transaction(prefix: client_schema)
    |> notify_on_creation(client_schema)
  end

  def update_approval(id, params, client_schema) do
    #    sort_logs = Enum.sort(params["logs"], &(&1["inserted_at"] >= &2["inserted_at"]))
    #    log = Enum.find(sort_logs |> Enum.with_index, fn {l, _idx} -> l["status"] != "Pending" end)

    logs =
      if params["logs"] do
        #        Enum.slice(sort_logs, i..length(sort_logs)) |> Enum.map(fn l -> l["id"] end)
        Enum.reduce(params["logs"], [], fn l, acc ->
          case l["status"] do
            "Pending" -> [l["id"] | acc]
            _ -> acc
          end
        end)
      end

    Multi.new()
    |> Multi.update(:approval, Approval.changeset(Repo.get(Approval, id), params))
    |> process_amounts_update(params["costs"], id)
    |> attach_attachments(params["attachments"])
    |> delete_log_on_edit(logs)
    |> create_and_notify_of_new_status(client_schema)
    |> Repo.transaction(prefix: client_schema)
  end

  defp create_and_notify_of_new_status(multi, client_schema) do
    log_multi = create_from_org_chart(multi)

    Multi.run(log_multi, :create_and_notify_of_new_status, fn _repo, cs ->
      approval = Approvals.show_approval(cs.approval.id, client_schema)

      property =
        AppCount.Properties.get_property(ClientSchema.new(client_schema, cs.approval.property_id))

      send_email(approval, property, cs.logs, client_schema)
      {:ok, "email sent"}
    end)
  end

  def delete_log_on_edit(multi, nil), do: multi

  def delete_log_on_edit(multi, logs) do
    Multi.update_all(multi, :approval_logs_deleted, from(a in ApprovalLog, where: a.id in ^logs),
      set: [deleted: true]
    )
  end

  def delete_approval(id) do
    Repo.get(Approval, id)
    |> Repo.delete()
  end

  defp process_amounts(multi, nil), do: multi

  defp process_amounts(multi, amounts) do
    Multi.run(
      multi,
      :amounts,
      fn _, cs ->
        Enum.reduce_while(
          amounts,
          {:ok, []},
          &generate_amount(Map.merge(&1, %{"approval_id" => cs.approval.id}), &2)
        )
      end
    )
  end

  defp process_amounts_update(multi, nil, _), do: multi

  defp process_amounts_update(multi, amounts, id) do
    Approvals.Utils.ApprovalCosts.delete_all(id)
    process_amounts(multi, amounts)
  end

  defp create_log(multi, nil), do: create_from_org_chart(multi)

  defp create_log(multi, approvers) do
    Multi.run(
      multi,
      :logs,
      fn _, cs ->
        Enum.reduce_while(
          approvers,
          {:ok, []},
          &generate_log(
            %{
              admin_id: &1,
              approval_id: cs.approval.id,
              status: "Pending",
              approval: cs.approval
            },
            &2
          )
        )
      end
    )
  end

  defp create_from_org_chart(multi) do
    # TODO:SCHEMA remove dasmen
    Multi.run(
      multi,
      :logs,
      fn _, cs ->
        case Admins.get_parent(ClientSchema.new("dasmen", cs.approval.admin_id)) do
          nil ->
            {:ok, multi}

          parent ->
            create_log_multi(
              %{admin_id: parent.id, approval_id: cs.approval.id, status: "Pending"},
              cs.approval
            )
        end
      end
    )
  end

  defp generate_log(params, {:ok, approvers}) do
    create_log_multi(params, params.approval)
    |> case do
      {:ok, approver} -> {:cont, {:ok, approvers ++ [approver]}}
      {:error, e} -> {:halt, {:error, e}}
    end
  end

  defp create_log_multi(params, _) do
    %ApprovalLog{}
    |> ApprovalLog.changeset(params)
    |> Repo.insert()
  end

  defp sort_email_map(acc, id, l, nil, nil), do: Map.put(acc, id, [l])
  defp sort_email_map(acc, id, l, _, nil), do: Map.put(acc, id, acc[id] ++ [l])

  defp sort_email_map(acc, id, l, val, next_admin) do
    # TODO:SCHEMA remove default schea
    if id <
         length(
           AppCount.Admins.Utils.OrgCharts.find_depth(ClientSchema.new("dasmen", next_admin.id))
         ) do
      sort_email_map(acc, id, l, val, nil)
    else
      acc
    end
  end

  # UNDER TESTED
  def find_emailer(approval, logs, client_schema, next_admin \\ nil) do
    full_approval = Approvals.show_approval(approval.id, client_schema)

    property =
      AppCount.Properties.get_property(ClientSchema.new(client_schema, approval.property_id))

    result =
      Enum.reduce(logs, %{}, fn l, acc ->
        id =
          length(
            AppCount.Admins.Utils.OrgCharts.find_depth(
              ClientSchema.new(client_schema, l.admin_id)
            )
          )

        sort_email_map(acc, id, l, acc[id], next_admin)
      end)
      |> Enum.to_list()
      |> Enum.sort(fn {k1, _v1}, {k2, _v2} -> k1 > k2 end)
      |> Enum.at(0)

    case result do
      {_key, email_logs} ->
        Enum.each(email_logs, fn log ->
          send_email(full_approval, property, log, client_schema)
        end)

        :ok

      something ->
        {:error, something}
    end
  end

  # UNTESTED
  defp send_email(full_approval, property, log, client_schema) do
    admin = Repo.get(AppCount.Admins.Admin, log.admin_id, prefix: client_schema)

    # FIX_DEPS
    token =
      AppCountWeb.Token.token(%{
        admin_id: log.admin_id,
        approval_log_id: log.id,
        approval_id: log.approval_id
      })

    AppCountCom.Approvals.notify_pending_of_approval(full_approval, admin, log, token, property)
  end

  defp notify_on_creation({:error, e}, _), do: {:error, e}

  defp notify_on_creation({:ok, %{approval: approval, logs: logs}} = res, schema)
       when is_list(logs) do
    AppCount.Core.Tasker.start(fn -> find_emailer(approval, logs, schema) end)
    res
  end

  defp notify_on_creation({:ok, %{approval: approval, logs: log}} = res, client_schema) do
    full_approval = Approvals.show_approval(approval.id, client_schema)

    property =
      AppCount.Properties.get_property(ClientSchema.new(client_schema, approval.property_id))

    AppCount.Core.Tasker.start(fn -> send_email(full_approval, property, log, client_schema) end)
    res
  end

  defp notify_on_creation(e, _), do: e

  defp attach_attachments(multi, nil), do: multi

  defp attach_attachments(multi, attachments) do
    Multi.run(
      multi,
      :attachments,
      fn _repo, cs ->
        Enum.reduce_while(
          attachments,
          {:ok, []},
          &create_attachment(
            %{
              "approval_id" => cs.approval.id,
              "attachment" => %{
                "uuid" => &1["uuid"]
              }
            },
            &2
          )
        )
      end
    )
  end

  # admin_property_ids = property_ids that this admin has access to,
  # filter_property_ids = property_ids that the front end is passing in.
  def list_approvals(admin_property_ids, filter_property_ids) do
    filter_property_ids = Enum.map(filter_property_ids, &String.to_integer(&1))

    if MapSet.subset?(MapSet.new(filter_property_ids), MapSet.new(admin_property_ids)) do
      filter_property_ids
      |> ApprovalRepo.list_approvals()
      |> map_data_from_repo
    else
      []
    end
  end

  def list_approvals(admin_id, :pending, property_ids) do
    rejected =
      from(
        l in ApprovalLog,
        join: a in assoc(l, :admin),
        select: %{
          id: l.id,
          status: l.status,
          approval_id: l.approval_id
        },
        where: l.status == "Declined" or l.status == "Cancelled"
      )

    log_query =
      from(
        l in ApprovalLog,
        join: a in assoc(l, :admin),
        select: %{
          id: l.id,
          admin_id: l.admin_id,
          inserted_at: l.inserted_at,
          status: l.status,
          notes: l.notes,
          admin: a.name,
          email: a.email,
          approval_id: l.approval_id
        },
        order_by: [
          desc: :inserted_at
        ]
      )

    from(
      a in Approval,
      join: l in subquery(log_query),
      on: l.approval_id == a.id,
      join:
        ls in subquery(
          log_query
          |> distinct([l], l.approval_id)
          |> order_by([l], desc: l.inserted_at)
          |> where([l], l.admin_id == ^admin_id)
        ),
      on: ls.approval_id == a.id,
      left_join: rj in subquery(rejected),
      on: rj.approval_id == a.id,
      left_join: at in assoc(a, :attachments),
      left_join: up in assoc(at, :attachment),
      left_join: url in assoc(at, :attachment_url),
      left_join: property in assoc(a, :property),
      join: admin in assoc(a, :admin),
      select: map(a, [:id, :type, :notes, :params, :property_id, :inserted_at, :num]),
      select_merge: %{
        requestor: map(admin, [:id, :name, :email]),
        logs: jsonize(l, [:id, :admin_id, :inserted_at, :status, :notes, :admin, :email]),
        attachments:
          type(
            jsonize(at, [:id, {:url, url.url}, {:content_type, up.content_type}]),
            AppCount.Data.Uploads
          ),
        property: property.name
      },
      where: ls.admin_id == ^admin_id and ls.status == "Pending" and is_nil(rj.id),
      where: a.property_id in ^property_ids,
      order_by: [
        asc: :inserted_at
      ],
      group_by: [a.id, admin.id, property.id]
    )
    |> Repo.all()
  end

  def map_data_from_repo([]), do: []

  def map_data_from_repo(approvals) do
    approvals
    |> Enum.map(fn app ->
      %{
        admin_notes: notes_from_preload(app.approval_notes),
        attachments: attachments_from_preload(app.attachments),
        costs: costs_from_preload(app.approval_costs),
        logs: logs_from_preload(app.approval_logs),
        requestor: requestor_from_preload(app.admin),
        property: app.property.name,
        property_id: app.property_id,
        id: app.id,
        inserted_at: app.inserted_at,
        notes: app.notes,
        num: app.num,
        params: app.params,
        type: app.type
      }
    end)
  end

  defp notes_from_preload([]), do: []

  defp notes_from_preload(notes) do
    notes
    |> Enum.map(fn n ->
      %{
        "id" => n.id,
        "note" => n.note,
        "admin_id" => n.admin_id,
        "admin" => n.admin.name,
        "email" => n.admin.email,
        "inserted_at" => n.inserted_at
      }
    end)
  end

  defp attachments_from_preload([]), do: []

  defp attachments_from_preload(attachments) do
    attachments
    |> Enum.map(fn att ->
      %{
        "content_type" => att.attachment.content_type,
        "id" => att.id,
        "inserted_at" => att.inserted_at,
        "url" => att.attachment_url.url
      }
    end)
  end

  defp costs_from_preload([]), do: []

  defp costs_from_preload(costs) do
    costs
    |> Enum.map(fn c ->
      %{
        "amount" => c.amount,
        "category_name" => c.category.name,
        "id" => c.id
      }
    end)
  end

  defp logs_from_preload([]), do: []

  defp logs_from_preload(logs) do
    logs
    |> Enum.filter(&(not &1.deleted))
    |> Enum.sort(&(NaiveDateTime.compare(&1.inserted_at, &2.inserted_at) != :gt))
    |> Enum.map(fn l ->
      %{
        "admin" => l.admin.name,
        "admin_id" => l.admin_id,
        "email" => l.admin.email,
        "id" => l.id,
        "inserted_at" => l.inserted_at,
        "status" => l.status,
        "notes" => l.notes
      }
    end)
  end

  def requestor_from_preload(admin) do
    %{
      email: admin.email,
      id: admin.id,
      name: admin.name
    }
  end

  def list_pending() do
    rejected =
      from(
        l in ApprovalLog,
        join: a in assoc(l, :admin),
        select: %{
          id: l.id,
          status: l.status,
          approval_id: l.approval_id
        },
        where: l.status == "Declined" or l.status == "Cancelled"
      )

    log_query =
      from(
        l in ApprovalLog,
        join: a in assoc(l, :admin),
        select: %{
          id: l.id,
          admin_id: l.admin_id,
          inserted_at: l.inserted_at,
          status: l.status,
          notes: l.notes,
          admin: a.name,
          email: a.email,
          approval_id: l.approval_id
        },
        order_by: [
          desc: :inserted_at
        ]
      )

    from(
      a in Approval,
      join: l in subquery(log_query),
      on: l.approval_id == a.id,
      join:
        ls in subquery(
          log_query
          |> distinct([l], l.approval_id)
          |> order_by([l], desc: l.inserted_at)
        ),
      on: ls.approval_id == a.id,
      left_join: rj in subquery(rejected),
      on: rj.approval_id == a.id,
      left_join: at in assoc(a, :attachments),
      left_join: up in assoc(at, :attachment),
      left_join: url in assoc(at, :attachment_url),
      join: admin in assoc(a, :admin),
      select: map(a, [:id, :type, :notes, :params, :property_id, :inserted_at, :num]),
      select_merge: %{
        requestor: map(admin, [:id, :name, :email]),
        logs: jsonize(l, [:id, :admin_id, :inserted_at, :status, :notes, :admin, :email]),
        attachments:
          type(
            jsonize(at, [:id, {:url, url.url}, {:content_type, up.content_type}]),
            AppCount.Data.Uploads
          )
      },
      where: ls.status == "Pending" and is_nil(rj.id),
      order_by: [
        asc: :inserted_at
      ],
      group_by: [a.id, admin.id]
    )
    |> Repo.all()
  end

  # Used in the react-router to be able to link to approvals

  #    |> Repo.one
  #    |> case do
  #        nil -> 0
  #        num -> num
  #       end

  def chart_data(admin, property_id) do
    property_ids =
      if property_id == "-1" do
        Admins.property_ids_for(ClientSchema.new("dasmen", admin))
      else
        [property_id]
      end

    %{
      monthly_amount: amount_query(property_ids, admin.id),
      monthly_category: category_query(property_ids, admin.id)
    }
  end

  def category_query(property_ids, admin) do
    start_date =
      AppCount.current_time()
      |> Timex.beginning_of_month()
      |> Timex.shift(months: -6)

    end_date =
      AppCount.current_time()
      |> Timex.end_of_month()

    rejected =
      from(
        l in ApprovalLog,
        join: a in assoc(l, :admin),
        select: %{
          id: l.id,
          status: l.status,
          approval_id: l.approval_id
        },
        where: l.status == "Declined" or l.status == "Cancelled"
      )

    approval =
      from(
        a in Approval,
        left_join: p in assoc(a, :property),
        left_join: t in subquery(rejected),
        on: t.approval_id == a.id,
        where: is_nil(t.id) and p.id in ^property_ids and a.admin_id == ^admin,
        select: %{
          id: a.id,
          inserted_at: a.inserted_at,
          property: p.name
        }
      )

    from(
      c in ApprovalCost,
      left_join: cat in assoc(c, :category),
      join: a in subquery(approval),
      on: c.approval_id == a.id,
      where: a.inserted_at <= ^end_date and a.inserted_at >= ^start_date,
      select: %{
        amount: count(cat.name),
        date: fragment("date_part('month', ?)", a.inserted_at),
        name: cat.name,
        property: a.property
      },
      group_by: [fragment("date_part('month', ?)", a.inserted_at), cat.name, a.property]
    )
    |> Repo.all()
  end

  def amount_query(property_ids, admin) do
    start_date =
      AppCount.current_time()
      |> Timex.beginning_of_month()
      |> Timex.shift(months: -6)

    end_date =
      AppCount.current_time()
      |> Timex.end_of_month()

    rejected =
      from(
        l in ApprovalLog,
        join: a in assoc(l, :admin),
        select: %{
          id: l.id,
          status: l.status,
          approval_id: l.approval_id
        },
        where: l.status == "Declined" or l.status == "Cancelled"
      )

    approval =
      from(
        a in Approval,
        left_join: p in assoc(a, :property),
        left_join: t in subquery(rejected),
        on: t.approval_id == a.id,
        where: is_nil(t.id) and p.id in ^property_ids and a.admin_id == ^admin,
        select: %{
          id: a.id,
          inserted_at: a.inserted_at,
          property: p.name
        }
      )

    from(
      c in ApprovalCost,
      left_join: cat in assoc(c, :category),
      join: a in subquery(approval),
      on: c.approval_id == a.id,
      where: a.inserted_at <= ^end_date and a.inserted_at >= ^start_date,
      select: %{
        amount: sum(c.amount),
        date: fragment("date_part('month', ?)", a.inserted_at),
        property: a.property,
        name: cat.name
      },
      group_by: [fragment("date_part('month', ?)", a.inserted_at), a.property, cat.name]
    )
    |> Repo.all()
  end

  def amount_spent_query() do
    start_date =
      AppCount.current_time()
      |> Timex.beginning_of_month()

    end_date =
      AppCount.current_time()
      |> Timex.end_of_month()

    rejected =
      from(
        l in ApprovalLog,
        join: a in assoc(l, :admin),
        select: %{
          id: l.id,
          status: l.status,
          approval_id: l.approval_id
        },
        where: l.status == "Declined" or l.status == "Cancelled"
      )

    approval =
      from(
        a in Approval,
        left_join: t in subquery(rejected),
        on: t.approval_id == a.id,
        where: is_nil(t.id),
        select: %{
          id: a.id,
          inserted_at: a.inserted_at,
          property_id: a.property_id
        }
      )

    from(
      c in ApprovalCost,
      join: a in subquery(approval),
      on: c.approval_id == a.id,
      where: a.inserted_at <= ^end_date and a.inserted_at >= ^start_date,
      select: %{
        amount: sum(c.amount),
        property_id: a.property_id,
        category_id: c.category_id
      },
      group_by: [a.property_id, c.category_id]
    )
  end

  def show_approval(id, schema) do
    log_query =
      from(
        l in ApprovalLog,
        join: a in assoc(l, :admin),
        select: %{
          approval_id: l.approval_id,
          approvals:
            jsonize(
              l,
              [
                :id,
                :admin_id,
                :inserted_at,
                :status,
                :notes,
                {:admin, a.name},
                {:email, a.email}
              ],
              l.inserted_at,
              "DESC"
            )
        },
        where: l.deleted != true,
        group_by: [l.approval_id]
      )

    notes_query =
      from(
        n in ApprovalNote,
        join: a in assoc(n, :admin),
        select: %{
          id: n.id,
          note: n.note,
          admin_id: n.admin_id,
          admin: a.name,
          email: a.email,
          inserted_at: n.inserted_at,
          approval_id: n.approval_id
        },
        order_by: [
          desc: :inserted_at
        ]
      )

    from(
      a in Approval,
      left_join: l in subquery(log_query),
      on: l.approval_id == a.id,
      left_join: n in subquery(notes_query),
      on: n.approval_id == a.id,
      left_join: c in assoc(a, :approval_costs),
      left_join: ca in subquery(amount_spent_query()),
      on:
        fragment("? = ? AND ? = ?", a.property_id, ca.property_id, c.category_id, ca.category_id),
      left_join: at in assoc(a, :attachments),
      left_join: up in assoc(at, :attachment),
      left_join: cat in assoc(c, :category),
      left_join: url in assoc(at, :attachment_url),
      join: admin in assoc(a, :admin),
      select: map(a, [:id, :type, :notes, :params, :property_id, :inserted_at, :num]),
      select_merge: %{
        requestor: map(admin, [:id, :name, :email]),
        logs: l.approvals,
        attachments:
          type(
            jsonize(at, [
              :id,
              {:url, url.url},
              {:content_type, up.content_type},
              {:filename, up.filename},
              {:inserted_at, up.inserted_at}
            ]),
            AppCount.Data.Uploads
          ),
        admin_notes:
          jsonize(n, [:id, :note, :admin_id, :admin, :email, :inserted_at, :approval_id]),
        costs: jsonize(c, [:id, :amount, :category_id, {:name, cat.name}, {:spent, ca.amount}])
      },
      where: a.id == ^id,
      order_by: [
        asc: :inserted_at
      ],
      group_by: [a.id, admin.id, l.approvals],
      limit: 1
    )
    |> Repo.one(prefix: schema)
  end

  # Pass in a property id and it will return all admins for that property that are Super Admin or Regional
  def list_approvers(admin) do
    # TODO:SCHEMA remove dasmen from ancestors
    admins =
      AppCount.Admins.Utils.OrgCharts.ancestors(ClientSchema.new("dasmen", admin.id))
      |> join(:inner, [ad], admin in assoc(ad, :admin))
      |> select(
        [ad, admin],
        %{
          id: admin.id,
          email: admin.email,
          name: admin.name
        }
      )
      |> Repo.all()
      |> List.insert_at(-1, %{id: admin.id, email: admin.email, name: admin.name})

    # TODO:SCHEMA remove dasmen from children
    children =
      AppCount.Admins.Utils.OrgCharts.children(ClientSchema.new("dasmen", admin.id))
      |> join(:inner, [ad], admin in assoc(ad, :admin))
      |> select(
        [ad, admin],
        %{
          id: admin.id,
          email: admin.email,
          name: admin.name
        }
      )
      |> Repo.all()

    admins ++ children
  end

  # Pass in a payee_id and a property_id to get the next number for the approval.
  # Note that this should be changed later when we use approvals for more than just purchases.
  # Maybe not require a payee_id or something, depending on the next system to use approvals.
  def get_next_num(_payee_id, nil) do
    "Error"
  end

  def get_next_num(nil, property_id) do
    from(
      a in Approval,
      where: a.property_id == ^property_id,
      where: ilike(a.num, "%Error%"),
      select: a.num
      #      order_by: [
      #        desc: :num
      #      ],
      #      limit: 1
    )
    |> Repo.all()
    |> sort_nums()
    |> case do
      nil -> "#{property_id}-Error-1"
      num -> get_num(num, "#{property_id}-Error")
    end
  end

  def get_next_num(payee_id, property_id) do
    from(
      a in Approval,
      where: a.property_id == ^property_id,
      where: fragment("(params->>'payee_id')::integer") == ^payee_id,
      select: a.num
    )
    |> Repo.all()
    |> sort_nums()
    |> case do
      nil -> "#{payee_id}-#{property_id}-1"
      num -> get_num(num, "#{payee_id}-#{property_id}")
    end
  end

  defp sort_nums(nums) when is_nil(nums), do: nil

  defp sort_nums(nums) do
    Enum.sort(nums, &(parsed(&1) >= parsed(&2)))
    |> List.first()
  end

  defp parsed(num) do
    Regex.split(~r{-}, num)
    |> List.last()
    |> String.to_integer()
  end

  defp get_num(num, string) do
    n =
      Regex.split(~r{-}, num)
      |> List.last()
      |> String.to_integer()

    "#{string}-#{n + 1}"
  end

  def generate_num(
        %{"params" => %{"payee_id" => payee_id}, "num" => num, "property_id" => property_id} =
          outer_params
      ) do
    num =
      if is_nil(num) || num == "" do
        get_next_num(payee_id, property_id)
      else
        num
      end

    Map.merge(outer_params, %{"num" => num})
  end

  defp generate_amount(params, {:ok, amounts}) do
    case params["amount"] do
      nil ->
        {:cont, {:ok, amounts}}

      _ ->
        %ApprovalCost{}
        |> ApprovalCost.changeset(params)
        |> Repo.insert()
        |> case do
          {:ok, amount} -> {:cont, {:ok, amounts ++ [amount]}}
          {:error, e} -> {:halt, {:error, e}}
        end
    end
  end

  defp create_attachment(params, {:ok, attachments}) do
    %ApprovalAttachment{}
    |> ApprovalAttachment.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, attachment} -> {:cont, {:ok, attachments ++ [attachment]}}
      {:error, e} -> {:halt, {:error, e}}
    end
  end

  def delete_attachment(id) do
    Repo.get(ApprovalAttachment, id)
    |> Repo.delete()
  end
end
