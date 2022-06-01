defmodule AppCount.Maintenance.Utils.Cards do
  alias AppCount.Admins
  alias AppCount.Maintenance
  alias AppCount.Maintenance.Assignment
  alias AppCount.Maintenance.Card
  alias AppCount.Maintenance.CardItem
  alias AppCount.Maintenance.Category
  alias AppCount.Maintenance.Order
  alias AppCount.Maintenance.Utils.CardItemPublisher
  alias AppCount.Maintenance.Utils.CardPublisher
  alias AppCount.Properties.Property
  alias AppCount.Repo
  alias AppCount.Vendors
  require Logger
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Core.ClientSchema

  def ready_and_not_ready_count(property) do
    ready_count = ready_units_count(property)
    not_ready_count = not_ready_units_count(property)

    %{
      ready: ready_count,
      not_ready: not_ready_count
    }
  end

  def list_cards(
        %ClientSchema{attrs: %{property_ids: property_ids} = _admin},
        p_ids,
        hidden \\ :not_hidden
      ) do
    hidden_value = hidden == :hidden

    from(
      card in Card,
      join: unit in assoc(card, :unit),
      join: property in assoc(unit, :property),
      left_join: icon in assoc(property, :icon_url),
      left_join: card_item in assoc(card, :items),
      left_join: technician in assoc(card_item, :tech),
      left_join: floor_plan in assoc(unit, :floor_plan),
      where: unit.property_id in ^property_ids,
      where: unit.property_id in ^p_ids,
      where: is_nil(card.bypass_date),
      where: card.hidden == ^hidden_value,
      select:
        map(
          card,
          [
            :id,
            :admin,
            :hidden,
            :deadline,
            :completion,
            :inserted_at,
            :priority,
            :move_in_date,
            :move_out_date
          ]
        ),
      select_merge: %{
        unit: %{
          id: unit.id,
          number: unit.number,
          area: unit.area,
          status: unit.status,
          floor_plan: floor_plan.name
        },
        property: %{
          id: property.id,
          name: property.name,
          icon: max(icon.url)
        },
        items:
          jsonize(
            card_item,
            [
              :id,
              :name,
              :notes,
              :completed,
              :scheduled,
              :tech_id,
              :vendor_id,
              :status,
              :confirmation,
              :completed_by,
              {:tech, technician.name}
            ]
          )
      },
      group_by: [card.id, unit.id, property.id, floor_plan.name]
    )
    |> Repo.all()
  end

  def create_card(params) do
    %Card{}
    |> Card.changeset(params)
    |> Repo.insert()
    |> case do
      {:ok, card} ->
        CardPublisher.publish_card_created_event(card.id)
        {:ok, card}

      e ->
        e
    end
  end

  def update_card(id, params) do
    Repo.get(Card, id)
    |> Card.changeset(params)
    |> Repo.update()
    |> case do
      {:ok, card} ->
        CardPublisher.publish_card_updated_event(card.id)
        {:ok, card}

      e ->
        e
    end
  end

  def create_card_item(%AppCount.Core.ClientSchema{name: client_schema, attrs: params}, admin) do
    %CardItem{}
    |> CardItem.changeset(params)
    |> Repo.insert(prefix: client_schema)
    |> case do
      {:ok, %{tech_id: id} = item} when not is_nil(id) ->
        assign_tech(ClientSchema.new(client_schema, item), nil, id, admin)
        CardItemPublisher.publish_card_item_created_event(item.id)
        {:ok, item}

      resp ->
        resp
    end
  end

  def update_card_item(
        id,
        %AppCount.Core.ClientSchema{name: client_schema, attrs: params},
        update_type \\ :updated
      ) do
    item =
      Repo.get(CardItem, id, prefix: client_schema)
      |> CardItem.changeset(params)
      |> Repo.update!(prefix: client_schema)

    case update_type do
      :completed -> CardItemPublisher.publish_card_item_completed_event(item.id)
      :confirmed -> CardItemPublisher.publish_card_item_confirmed_event(item.id)
      :reverted -> CardItemPublisher.publish_card_item_reverted_event(item.id)
      _ -> CardItemPublisher.publish_card_item_updated_event(item.id)
    end

    tech_id = params["tech_id"]
    vendor_id = params["vendor_id"]
    maintenance_order = Repo.get_by(Order, card_item_id: item.id)
    vendor_order = Repo.get_by(Vendors.Order, card_item_id: item.id)

    admin = params["admin"]

    scheduled = params["scheduled"]
    todays_date = Timex.format!(AppCount.current_time(), "{YYYY}-{0M}-{0D}")

    if scheduled == todays_date || scheduled == "" || vendor_id || scheduled == nil do
      if not is_nil(maintenance_order) and tech_id != item.tech_id do
        revoke_tech(%AppCount.Core.ClientSchema{name: client_schema, attrs: item})
      end

      if is_nil(vendor_order) and is_nil(vendor_id) and not is_nil(tech_id) do
        assign_tech(
          %AppCount.Core.ClientSchema{name: client_schema, attrs: item},
          item.tech_id,
          params["tech_id"],
          admin
        )
      end

      if not is_nil(vendor_order) and not is_nil(tech_id) and is_nil(vendor_id) do
        insource_order(
          %AppCount.Core.ClientSchema{name: client_schema, attrs: item},
          item.tech_id,
          Map.merge(convert_param(params), vendor_order),
          admin
        )
      end

      if not is_nil(vendor_order) and is_nil(maintenance_order) and not is_nil(vendor_id) and
           is_nil(tech_id) do
        AppCount.Vendors.Utils.Orders.update_order(Map.merge(vendor_order, convert_param(params)))
      end

      cond do
        not is_nil(maintenance_order) and not is_nil(vendor_id) and is_nil(tech_id) ->
          convert_param(params)
          |> AppCount.Vendors.Utils.Orders.create_order(maintenance_order)

        true ->
          nil
      end

      is_nil(maintenance_order) && is_nil(vendor_order) && vendor_id && is_nil(tech_id) &&
        AppCount.Vendors.Utils.Orders.create_new_order(params)
    else
      if is_nil(maintenance_order) do
        create_item_order(%AppCount.Core.ClientSchema{name: client_schema, attrs: item}, admin)
      else
        revoke_tech(%AppCount.Core.ClientSchema{name: client_schema, attrs: item})
      end
    end

    {:ok, item}
  end

  def insource_order(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: item},
        o_id,
        params,
        admin
      ) do
    AppCount.Vendors.OrderRepo.delete(ClientSchema.new(client_schema, params.id))

    assign_tech(
      %AppCount.Core.ClientSchema{name: client_schema, attrs: item},
      o_id,
      params.tech_id,
      admin
    )
  end

  def convert_param(params) do
    %{
      vendor_id: params["vendor_id"],
      tech_id: params["tech_id"],
      vendor_category_id: Repo.get_by!(Vendors.Category, name: "Make Ready").id
    }
  end

  def complete_card_item(id, %AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    item =
      Repo.get(CardItem, id, prefix: client_schema)
      |> CardItem.changeset(params)
      |> Repo.update!(prefix: client_schema)

    CardItemPublisher.publish_card_item_completed_event(item.id)
  end

  def complete_card_item(
        "create",
        %AppCount.Core.ClientSchema{name: client_schema, attrs: params},
        admin
      ) do
    case create_card_item(%AppCount.Core.ClientSchema{name: client_schema, attrs: params}, admin) do
      {:ok, item} ->
        complete_card_item(
          item.id,
          %AppCount.Core.ClientSchema{name: client_schema, attrs: params},
          admin
        )

      e ->
        e
    end
  end

  def complete_card_item(
        id,
        %AppCount.Core.ClientSchema{name: client_schema, attrs: params},
        admin
      ) do
    item =
      update_card_item(
        id,
        ClientSchema.new(
          client_schema,
          %{
            "completed_by" => admin.name,
            "status" => "Admin Completed",
            "completed" => AppCount.current_date(),
            "admin_id" => params["admin_id"]
          }
        ),
        :completed
      )

    params["vendor_id"] && complete_or_revert_vendor_order(id, params)
    item
  end

  def revert_card_item(id, %AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    item =
      update_card_item(
        id,
        ClientSchema.new(
          client_schema,
          %{
            "completed_by" => nil,
            "status" => nil,
            "completed" => nil,
            "admin_id" => params["admin_id"]
          }
        ),
        :reverted
      )

    params["vendor_id"] && complete_or_revert_vendor_order(id, params)
    item
  end

  def complete_or_revert_vendor_order(card_item_id, params) do
    map =
      case params["completed"] do
        nil -> %{status: "Open"}
        _ -> %{status: "Completed"}
      end

    case Repo.get_by(Vendors.Order, card_item_id: card_item_id) do
      %Vendors.Order{} = order ->
        order
        |> Vendors.Order.changeset(map)
        |> Repo.update()

      # If we do not find anything here, it is because this is a make-ready card
      # rather than a vendor order. Unfortunately there is no way to tell from
      # the card item whether it belongs to a Vendor Order or a Card.
      _ ->
        nil
    end
  end

  def confirm_card_item(
        id,
        %AppCount.Core.ClientSchema{name: client_schema, attrs: params},
        admin
      ) do
    new_params =
      params
      |> Map.merge(%{
        "confirmation" => %{
          name: admin,
          date: AppCount.current_time()
        }
      })

    update_card_item(id, ClientSchema.new(client_schema, new_params), :confirmed)
  end

  def delete_card_item(admin, %AppCount.Core.ClientSchema{name: client_schema, attrs: id}) do
    Repo.get(CardItem, id)
    |> Repo.preload(card: :unit)
    |> AppCount.Admins.Utils.Actions.admin_delete(ClientSchema.new(client_schema, admin))
    |> case do
      {:ok, card_item} ->
        CardItemPublisher.publish_card_item_deleted_event(card_item)
        {:ok, card_item}

      e ->
        e
    end
  end

  def get_card_items_by_date(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: property_ids
        },
        date
      ) do
    from(
      i in CardItem,
      join: c in assoc(i, :card),
      join: u in assoc(c, :unit),
      join: p in assoc(u, :property),
      where: i.scheduled == ^date and is_nil(i.completed) and u.property_id in ^property_ids,
      select: %{
        id: c.id,
        name: i.name,
        notes: i.notes,
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
    |> Repo.all(prefix: client_schema)
  end

  defp assign_tech(_, _, nil, _), do: nil

  defp assign_tech(
         %ClientSchema{name: client_schema, attrs: item},
         nil,
         new_tech_id,
         admin
       ) do
    order =
      Repo.get_by(Order, [card_item_id: item.id], prefix: client_schema) ||
        create_item_order(%ClientSchema{name: client_schema, attrs: item}, admin)

    Maintenance.assign_order(
      %ClientSchema{name: client_schema, attrs: order.id},
      new_tech_id,
      admin.id
    )
  end

  defp assign_tech(
         %ClientSchema{name: client_schema, attrs: item},
         _old_tech_id,
         new_tech_id,
         admin
       ) do
    order =
      Repo.get_by(Order, card_item_id: item.id, prefix: client_schema) ||
        create_item_order(%ClientSchema{name: client_schema, attrs: item}, admin)

    case Repo.get_by(Assignment, [order_id: order.id], prefix: client_schema) do
      nil ->
        %ClientSchema{name: client_schema, attrs: order.id}
        |> Maintenance.assign_order(new_tech_id, admin.id)

      assignment ->
        assignment
        |> Assignment.changeset(%{
          tech_id: new_tech_id,
          confirmed_at: DateTime.utc_now(),
          status: "in_progress"
        })
        |> Repo.update!(prefix: client_schema)
        |> AppCount.Maintenance.Utils.Assignments.update_order_status("assigned", order.id)
    end
  end

  def revoke_tech(%AppCount.Core.ClientSchema{name: client_schema, attrs: item}) do
    order = Repo.get_by(Order, [card_item_id: item.id], prefix: client_schema)

    case Repo.get_by(Assignment, [order_id: order.id], prefix: client_schema) do
      nil ->
        nil

      assignment ->
        %AppCount.Core.ClientSchema{name: client_schema, attrs: item}
        |> Map.put(:attrs, assignment.id)
        |> Maintenance.revoke_assignment()
    end
  end

  def get_ready_by_dates(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: admin
        },
        start_date,
        end_date \\ nil
      ) do
    start_ts =
      Timex.beginning_of_day(start_date)
      |> Timex.to_unix()

    end_ts =
      Timex.end_of_day(end_date || start_date)
      |> Timex.to_unix()

    sub_query =
      from(
        ci in CardItem,
        join: c in assoc(ci, :card),
        join: l in assoc(c, :lease),
        join: u in assoc(l, :unit),
        join: p in assoc(u, :property),
        where:
          ci.name == "Final Inspection" and
            (not is_nil(ci.completed) and
               fragment(
                 "EXTRACT(EPOCH FROM ?) BETWEEN ? AND ?",
                 ci.completed,
                 ^start_ts,
                 ^end_ts
               )),
        select: %{
          property_id: p.id,
          count: count(ci.id)
        },
        group_by: [p.id]
      )

    from(
      p in AppCount.Properties.Property,
      left_join: ci in subquery(sub_query),
      on: ci.property_id == p.id,
      select: %{
        id: p.id,
        name: p.name,
        completed: ci.count
      },
      where: p.id in ^admin.property_ids,
      group_by: [p.id, ci.count],
      order_by: [
        asc: :name
      ]
    )
    |> Repo.all(prefix: client_schema)
  end

  def not_ready_units(admin) do
    property_ids = Admins.property_ids_for(admin)

    item_query =
      from(
        i in CardItem,
        select: %{
          card_id: i.card_id,
          id: i.id
        },
        where: is_nil(i.completed)
      )

    from(
      c in Card,
      join: u in assoc(c, :unit),
      join: p in assoc(u, :property),
      join: i in subquery(item_query),
      on: i.card_id == c.id,
      where: u.property_id in ^property_ids,
      select: %{
        id: c.id,
        move_out: c.move_out_date,
        property: p.name,
        unit: u.number
      },
      distinct: u.id
    )
    |> Repo.all()
  end

  # counts how many units are not ready. "Not ready" is defined as lacking a populated
  # completion field
  def not_ready_units_count(%Property{} = property) do
    from(
      c in Card,
      join: u in assoc(c, :unit),
      on: u.property_id == ^property.id,
      where: is_nil(c.completion) or is_nil(fragment("completion->>'date'")),
      where: c.hidden == false
    )
    |> Repo.count()
  end

  def ready_units_count(%Property{} = property) do
    from(
      c in Card,
      join: u in assoc(c, :unit),
      on: u.property_id == ^property.id,
      where: not is_nil(c.completion) and not is_nil(fragment("completion->>'date'")),
      where: c.hidden == false
    )
    |> Repo.count()
  end

  def create_item_order(%AppCount.Core.ClientSchema{name: client_schema, attrs: item}),
    do: create_item_order(%AppCount.Core.ClientSchema{name: client_schema, attrs: item}, nil)

  def create_item_order(%AppCount.Core.ClientSchema{name: client_schema, attrs: item}, nil) do
    card =
      Repo.get(Card, item.card_id, prefix: client_schema)
      |> Repo.preload(:unit)

    admin = Repo.get_by(AppCount.Admins.Admin, [name: card.admin], prefix: client_schema)

    create_item_order(%AppCount.Core.ClientSchema{name: client_schema, attrs: item}, admin)
  end

  def create_item_order(%AppCount.Core.ClientSchema{name: client_schema, attrs: item}, admin) do
    card =
      Repo.get(Card, item.card_id, prefix: client_schema)
      |> Repo.preload(:unit)

    params = %{
      unit_id: card.unit_id,
      property_id: card.unit.property_id,
      category_id: category_id_for({item, client_schema}),
      has_pet: false,
      entry_allowed: true,
      ticket: "0000000000",
      priority: 1,
      card_item_id: item.id,
      uuid: UUID.uuid4(),
      note: item.notes,
      admin_id: admin.id
    }

    {:ok, order} =
      Maintenance.create_order(%AppCount.Core.ClientSchema{name: client_schema, attrs: params})

    order
  end

  defp category_id_for({item, schema}) do
    from(
      c in Category,
      join: sc in assoc(c, :parent),
      where: sc.name == "Make Ready" and c.name == ^item.name,
      select: %{
        id: c.id
      }
    )
    |> Repo.one(prefix: schema)
    |> case do
      nil ->
        {:ok, %{id: cat_id}} =
          Maintenance.create_category(
            {%{
               "name" => item.name,
               "visible" => false,
               "path" => [card_item_tl_category_id(schema)]
             }, schema}
          )

        cat_id

      %{id: id} ->
        id
    end
  end

  defp card_item_tl_category_id(schema) do
    Repo.get_by(Category, name: "Make Ready")
    |> case do
      nil ->
        {:ok, %{id: id}} =
          Maintenance.create_category({%{name: "Make Ready", visible: false}, schema})

        id

      %{id: id} ->
        id
    end
  end
end
