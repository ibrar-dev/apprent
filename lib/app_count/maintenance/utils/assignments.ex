defmodule AppCount.Maintenance.Utils.Assignments do
  import Ecto.Query
  alias AppCount.Maintenance
  alias AppCount.Maintenance.Utils.OrderPublisher
  alias AppCount.Maintenance.Assignment
  alias AppCount.Maintenance.Order
  alias AppCount.Maintenance.Note
  alias AppCount.Maintenance.Tech
  alias AppCount.Materials.Material
  alias AppCount.Repo
  alias Ecto.Multi
  alias AppCount.Core.ClientSchema
  require Logger

  def assign_order(order_id, tech_id, admin_id) do
    if can_assign?(order_id) do
      insert_in_progress(order_id, tech_id, admin_id)
      |> notify_assignment
      |> notify_tenant_assigned
      |> OrderPublisher.publish_order_assigned_event()
    else
      # check_for_dupes(order_id)
      revoke_and_assign(order_id, tech_id, admin_id)
    end
  end

  def revoke_and_assign(order_id, tech_id, admin_id) do
    revoke_open(order_id)

    if can_assign?(order_id) do
      assign_order(order_id, tech_id, admin_id)
    else
      check_for_dupes(order_id)
    end
  end

  defp revoke_open(%ClientSchema{attrs: order_id, name: client_schema} = schema) do
    from(
      a in Assignment,
      where: a.order_id == ^order_id and a.status in ["in_progress", "on_hold"]
    )
    |> Repo.all(prefix: client_schema)
    |> Enum.each(&Repo.delete(&1, prefix: client_schema))
    |> update_order_status("unassigned", schema)
  end

  def check_for_dupes(%ClientSchema{name: client_schema, attrs: order_id}) do
    from(
      a in Assignment,
      where: a.order_id == ^order_id,
      select: %{
        id: a.id,
        status: a.status,
        inserted_at: a.inserted_at,
        tech_id: a.tech_id,
        order_id: a.order_id
      },
      order_by: [
        desc: a.inserted_at
      ]
    )
    |> Repo.all(prefix: client_schema)
    |> AppCountCom.WorkOrders.duplicate_assignments()
  end

  def assign_orders(%ClientSchema{name: client_schema, attrs: order_ids}, tech_id, admin_id) do
    order_ids
    |> Enum.each(fn order_id ->
      assign_order(ClientSchema.new(client_schema, order_id), tech_id, admin_id)
    end)
  end

  @spec revoke_assignment(String.t() | integer) :: %Assignment{}
  def revoke_assignment(%ClientSchema{name: client_schema, attrs: id}) do
    a = Repo.get(Assignment, id, prefix: client_schema)

    del =
      Repo.delete(a, prefix: client_schema)
      |> update_order_status("unassigned", ClientSchema.new(client_schema, a.order_id))

    AppCount.Core.Tasker.start(fn ->
      notify_tech(a)
    end)

    del
  end

  def revoke_assignments(%ClientSchema{name: client_schema, attrs: ids}) when is_list(ids) do
    Enum.each(ids, fn id -> revoke_assignment(%ClientSchema{name: client_schema, attrs: id}) end)
  end

  @spec reject_assignment(%ClientSchema{}, String.t()) ::
          {:error, :bad_params} | %Assignment{}
  def reject_assignment(%ClientSchema{name: client_schema, attrs: id}, reason) do
    case Repo.get(Assignment, id, prefix: client_schema) do
      nil ->
        {:error, :bad_params}

      assignment ->
        assignment
        |> Assignment.changeset(%{status: "withdrawn", tech_comments: reason})
        |> Repo.update!(prefix: client_schema)
        |> update_order_status("unassigned", ClientSchema.new(client_schema, assignment.order_id))
        |> notify_tech
        |> notify_of_withdrawal
    end
  end

  @spec accept_assignment(%ClientSchema{}) :: %Assignment{}
  def accept_assignment(%ClientSchema{name: client_schema, attrs: id}) do
    now = DateTime.utc_now()

    Repo.get(Assignment, id, prefix: client_schema)
    |> Assignment.changeset(%{status: "in_progress", confirmed_at: now})
    |> Repo.update!(prefix: client_schema)
    |> notify_tech
  end

  @spec attach_material(String.t() | integer, integer, String.t() | integer) ::
          %Assignment{} | String.t()
  def attach_material(id, num, assignment_id) do
    assignment = Repo.get(Assignment, assignment_id)
    material = Repo.get(Material, id)

    mat = [
      %{num: num, cost: Decimal.to_float(material.cost), name: material.name}
      | assignment.materials
    ]

    Assignment.changeset(assignment, %{materials: mat})
    |> Repo.update()
  end

  def adjust_inventory({:error, _}, _), do: nil

  def adjust_inventory({:ok, _}, _) do
  end

  @spec remove_material(%ClientSchema{}, map) :: %Assignment{}
  def remove_material(%ClientSchema{name: client_schema, attrs: assignment_id}, %{
        "num" => _,
        "name" => name
      }) do
    assignment = Repo.get(Assignment, assignment_id, prefix: client_schema)
    materials = Enum.filter(assignment.materials, &(&1["name"] != name))
    a_cs = Assignment.changeset(assignment, %{materials: materials})
    change_inv(a_cs)
  end

  # UNTESTED
  def complete_assignment(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: id},
        details,
        tech_id
      ) do
    tech =
      from(t in Tech, where: t.id == ^tech_id, limit: 1, select: t.name)
      |> Repo.one(prefix: client_schema)

    case Repo.get(Assignment, id, prefix: client_schema) do
      nil ->
        {:error, :bad_params}

      assignment ->
        assignment =
          details
          |> Map.merge(%{"completed_at" => DateTime.utc_now(), "status" => "completed"})
          |> do_completion_update(assignment)
          |> complete_card_item(ClientSchema.new(client_schema, tech))
          |> notify_tech()

        ClientSchema.new(client_schema, assignment)
        |> notify_tenant_order_completed()

        OrderPublisher.publish_order_completed_event(assignment)
    end
  end

  def complete_assignment(%AppCount.Core.ClientSchema{name: client_schema, attrs: id}, details) do
    case Repo.get(Assignment, id, prefix: client_schema) do
      nil ->
        {:error, :bad_params}

      assignment ->
        assignment =
          details
          |> Map.put_new(:completed_at, DateTime.utc_now())
          |> Map.put(:status, "completed")
          |> do_completion_update(assignment)
          |> complete_card_item(ClientSchema.new(client_schema, %{}))
          |> notify_tech()

        ClientSchema.new(client_schema, assignment)
        |> notify_tenant_order_completed()

        OrderPublisher.publish_order_completed_event(assignment)

        assignment
    end
  end

  def notify_assignment({:ok, assignment}), do: notify_tech(assignment)
  def notify_assignment({:error, _changeset}), do: nil
  def notify_assignment({:error, _}, _), do: nil

  @spec notify_tech(%Assignment{}) :: %Assignment{}
  def notify_tech(assignment) do
    AppCount.Core.Tasker.start(__MODULE__, :notify_tech_task, [assignment])
    assignment
  end

  def notify_tech_task(assignment) do
    tech_id =
      from(a in Assignment, where: a.id == ^assignment.id, select: a.tech_id, limit: 1)
      |> Repo.one(prefix: assignment.__meta__.prefix)

    {property, unit, category} =
      from(
        o in Order,
        join: p in assoc(o, :property),
        left_join: u in assoc(o, :unit),
        join: sc in assoc(o, :category),
        join: c in assoc(sc, :parent),
        where: o.id == ^assignment.order_id,
        select: {
          p.name,
          u.number,
          fragment("? || ' > ' || ?", c.name, sc.name)
        },
        limit: 1
      )
      |> Repo.one()

    ClientSchema.new(assignment.__meta__.prefix, assignment.tech_id)
    |> AppCountWeb.TechChannel.send_tech_data()

    case tech_id do
      # why would this ever happen?
      0 ->
        nil

      _ ->
        unit_info = if unit, do: "\nUnit: #{unit} \n", else: "\n"

        ClientSchema.new(assignment.__meta__.prefix, tech_id)
        |> AppCountWeb.TechChannel.send_tech_notification(
          "New Work Order Assignment",
          "#{property} #{unit_info}#{category}"
        )
    end

    assignment
  end

  def list_tech_notes(order_id) do
    from(
      a in Assignment,
      join: t in assoc(a, :tech),
      where: a.order_id == ^order_id and not is_nil(a.tech_comments),
      select: %{
        tech: t.name,
        comment: a.tech_comments,
        id: a.id
      }
    )
    |> Repo.all()
  end

  @spec notify_tenant_order_completed(%Assignment{}) :: %Assignment{}
  def notify_tenant_order_completed(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: assignment
      }) do
    {order_id, ticket, email, notes, property} =
      from(
        o in Order,
        left_join: t in assoc(o, :tenant),
        join: p in assoc(o, :property),
        left_join: logo in assoc(p, :logo_url),
        left_join: n in Note,
        on: n.order_id == o.id and not is_nil(n.tenant_id),
        where: o.id == ^assignment.order_id,
        select: {o.id, o.ticket, t.email, n.text, merge(p, %{logo: logo.url})}
      )
      |> Repo.all(prefix: client_schema)
      |> List.first()

    # FIX_DEPS
    token_fn = &AppCountWeb.Token.token/1

    token =
      AppCount.Maintenance.Utils.Public.Orders.public_rate_token(
        ClientSchema.new(client_schema, order_id),
        token_fn
      )

    if !third_party(ClientSchema.new(client_schema, assignment.order_id)) && !is_nil(email) do
      maybe_mail_order_completed(
        email,
        ticket,
        notes,
        token,
        property
      )
    end
  end

  defp maybe_mail_order_completed(email, ticket, notes, token, property)
       when not is_nil(ticket) and not is_nil(notes) and
              not is_nil(property) do
    AppCountCom.WorkOrders.order_completed(email, ticket, notes, token, property)
  end

  defp maybe_mail_order_completed(email, ticket, notes, token, property) do
    Logger.error(
      "FAILED mail_order_completed(#{inspect(email)}, #{inspect(ticket)}, #{inspect(notes)}, #{
        inspect(token)
      }, #{inspect(property)})"
    )
  end

  def tech_dispatched(%ClientSchema{name: client_schema, attrs: assignment_id}, time) do
    assignment =
      Repo.get(Assignment, assignment_id, prefix: client_schema)
      |> OrderPublisher.publish_tech_dispatched_event()

    case from(
           o in Order,
           left_join: t in assoc(o, :tenant),
           join: u in assoc(o, :unit),
           join: p in assoc(u, :property),
           left_join: l in assoc(p, :logo_url),
           join: a in assoc(o, :assignments),
           join: tech in assoc(a, :tech),
           where: o.id == ^assignment.order_id and a.id == ^assignment_id,
           select: {tech.name, o.ticket, merge(p, %{logo: l.url}), t.email}
         )
         |> Repo.one(prefix: client_schema) do
      {tech, ticket, property, email} ->
        if email do
          AppCountCom.WorkOrders.tech_arrival(time, tech, ticket, property, email)
        end

      _ ->
        Logger.error(
          "#{__MODULE__} tech_dispatched/2 Order with Assignment(#{assignment_id}) not Found"
        )
    end
  end

  def notify_tenant_assigned(assignment) do
    # TODO:SCHEMA
    AppCount.Core.Tasker.start(fn ->
      do_notify_tenant_assigned(ClientSchema.new("dasmen", assignment))
    end)

    assignment
  end

  def do_notify_tenant_assigned(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: assignment
      }) do
    {tech, tech_image, ticket, property, email, first_name, last_name} =
      from(
        o in Order,
        left_join: t in assoc(o, :tenant),
        left_join: p in assoc(o, :property),
        left_join: l in assoc(p, :logo_url),
        join: a in assoc(o, :assignments),
        join: tech in assoc(a, :tech),
        where: o.id == ^assignment.order_id and a.id == ^assignment.id,
        select: {
          tech.name,
          tech.image,
          o.ticket,
          merge(p, %{logo: l.url}),
          t.email,
          t.first_name,
          t.last_name
        }
      )
      |> Repo.one(prefix: client_schema)

    if !third_party(ClientSchema.new(client_schema, assignment.order_id)) && !is_nil(email) do
      AppCountCom.WorkOrders.order_assigned(
        tech,
        tech_image,
        ticket,
        property,
        email,
        first_name,
        last_name
      )
    end
  end

  @spec rate_assignment(number | String.t(), integer) :: {:ok, term} | {:error, term}
  def rate_assignment(id, rating) do
    Repo.get(Assignment, id)
    |> Assignment.changeset(%{rating: rating})
    |> Repo.update()
  end

  @spec callback_assignment(%Assignment{}) :: %Assignment{}
  def callback_assignment(assignment) do
    schema = ClientSchema.new(assignment.__meta__.prefix, assignment.order_id)

    Assignment.changeset(assignment, %{status: "callback"})
    |> Repo.update!(prefix: schema.name)
    |> update_order_status("unassigned", schema)
  end

  @spec resident_callback_assignment(%Assignment{}, String.t()) :: %Assignment{}
  def resident_callback_assignment(assignment_id, note) do
    Repo.get(Assignment, assignment_id)
    |> callback_assignment(%{name: "Resident"}, note)
  end

  @spec callback_assignment(%Assignment{}, %{name: String.t()}, String.t()) :: %Assignment{}
  def callback_assignment(assignment, admin, note) do
    schema = ClientSchema.new(assignment.__meta__.prefix, assignment.order_id)

    Assignment.changeset(
      assignment,
      %{
        status: "callback",
        callback_info: %{
          admin_name: admin.name,
          callback_time: AppCount.current_time(),
          note: note
        }
      }
    )
    |> Repo.update(prefix: schema.name)
    |> update_order_status("unassigned", schema)
  end

  def bug_resident_about_rating(admin, assignment_id) do
    assignment = Repo.get(Assignment, assignment_id)
    current_ts = :os.system_time(:seconds)

    new_value =
      [%{name: admin.name, time: current_ts}]
      |> Enum.concat(assignment.email || [])

    assignment
    |> Assignment.changeset(%{email: new_value})
    |> Repo.update()
    |> case do
      {:ok, assignment} -> bug_resident(assignment)
      {:error, e} -> {:error, e}
    end
  end

  def bug_resident(assignment) do
    assignment
    |> get_reminder_to_rate_order_info()
    |> AppCountCom.WorkOrders.reminder_to_rate_order()
  end

  def get_reminder_to_rate_order_info(assignment) do
    from(
      o in Order,
      join: t in assoc(o, :tenant),
      join: p in assoc(o, :property),
      left_join: l in assoc(p, :logo_url),
      where: ^assignment.order_id == o.id,
      select: {
        fragment("? || ' ' || ?", t.first_name, t.last_name),
        o.ticket,
        t.email,
        merge(p, %{logo: l.url}),
        o.id
      }
    )
    |> Repo.one()

    # {"Larry-0 Smith", "UNKNOWN", "someguy0@yahoo.com", property, order_id }
  end

  @spec pause_assignment(String.t() | integer, integer) :: %Assignment{}
  def pause_assignment(
        %ClientSchema{name: client_schema, attrs: assignment_id},
        current_ts \\ :os.system_time(:seconds)
      ) do
    assignment = Repo.get(Assignment, assignment_id, prefix: client_schema)

    assignment
    |> Assignment.changeset(%{
      status: "on_hold",
      history: assignment.history ++ [%{"paused" => current_ts}]
    })
    |> Repo.update!(prefix: client_schema)
  end

  @spec resume_assignment(String.t() | integer, integer) :: %Assignment{}
  def resume_assignment(
        %ClientSchema{name: client_schema, attrs: assignment_id},
        current_ts \\ :os.system_time(:seconds)
      ) do
    assignment = Repo.get(Assignment, assignment_id, prefix: client_schema)

    assignment
    |> Assignment.changeset(%{
      status: "in_progress",
      history: assignment.history ++ [%{"resumed" => current_ts}]
    })
    |> Repo.update!(prefix: client_schema)
  end

  def update_order_status(pass_through, status, %ClientSchema{
        name: client_schema,
        attrs: order_id
      }) do
    Repo.get(Order, order_id, prefix: client_schema)
    |> Order.changeset(%{status: status})
    |> Repo.update(prefix: client_schema)

    pass_through
  end

  def delete_assignment(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: admin},
        assignment_id
      ) do
    Repo.get(Assignment, assignment_id, prefix: client_schema)
    |> AppCount.Admins.Utils.Actions.admin_delete(ClientSchema.new(client_schema, admin))
  end

  defp notify_of_withdrawal(assignment) do
    {property_id, tech, ticket} =
      from(
        a in Assignment,
        join: t in assoc(a, :tech),
        join: o in assoc(a, :order),
        left_join: p in assoc(o, :property),
        where: a.id == ^assignment.id,
        select: {p.id, t.name, o.ticket}
      )
      |> Repo.one(prefix: assignment.__meta__.prefix)

    mailer_property =
      AppCount.Properties.get_property(ClientSchema.new(assignment.__meta__.prefix, property_id))

    AppCount.Admins.admins_for(ClientSchema.new(assignment.__meta__.prefix, property_id), ["Tech"])
    |> Enum.each(fn a ->
      AppCountCom.WorkOrders.assignment_withdrawal(mailer_property, tech, ticket, assignment, a)
    end)
  end

  def insert_in_progress(
        %ClientSchema{name: client_schema, attrs: order_id} = schema,
        tech_id,
        admin_id
      ) do
    now = DateTime.utc_now()

    %Assignment{}
    |> Assignment.changeset(%{
      order_id: order_id,
      tech_id: tech_id,
      admin_id: admin_id,
      status: "on_hold",
      confirmed_at: now
    })
    |> Repo.insert(prefix: client_schema)
    |> update_order_status("assigned", schema)
  end

  defp do_completion_update(params, assignment) do
    schema = ClientSchema.new(assignment.__meta__.prefix, assignment.order_id)

    Assignment.changeset(assignment, params)
    |> Repo.update!(prefix: assignment.__meta__.prefix)
    |> update_order_status("completed", schema)
  end

  defp complete_card_item(assignment, %AppCount.Core.ClientSchema{
         name: client_schema,
         attrs: tech
       }) do
    from(o in Order, where: o.id == ^assignment.order_id, select: o.card_item_id)
    |> Repo.one(prefix: client_schema)
    |> case do
      nil ->
        assignment

      id ->
        date =
          AppCount.current_time()
          |> Timex.to_date()

        Maintenance.complete_card_item(
          id,
          ClientSchema.new(client_schema, %{completed: date, completed_by: tech})
        )

        assignment
    end
  end

  def can_assign?(%ClientSchema{name: client_schema, attrs: order_id}) do
    from(
      a in Assignment,
      where:
        a.order_id == ^order_id and a.status in ["pending", "in_progress", "completed", "on_hold"],
      select: count(a.id)
    )
    |> Repo.one(prefix: client_schema)
    |> Kernel.==(0)
  end

  def can_assign?(order_id) do
    # TODO FIXME needs to fix the stack calling into here.
    # HB: https://app.honeybadger.io/projects/79008/faults/80408120
    can_assign?(%ClientSchema{name: "dasmen", attrs: order_id})
  end

  defp change_inv(a_cs) do
    Multi.new()
    |> Multi.update(:assignment, a_cs)
    |> Repo.transaction()
    |> case do
      {:ok, changes} -> changes.assignment
      {:error, error} -> error
    end
  end

  def third_party(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: order_id
      }) do
    from(
      o in Order,
      join: c in assoc(o, :category),
      where: o.id == ^order_id,
      select: c.third_party,
      limit: 1
    )
    |> Repo.one(prefix: client_schema)
  end
end
