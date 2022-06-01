defmodule AppCount.Tasks.Workers.ScheduledCards do
  import Ecto.Query
  alias AppCount.Maintenance
  alias AppCount.Repo
  use AppCount.Tasks.Worker, "Scheduled make ready cards"

  @impl AppCount.Tasks.Worker
  def perform(schema \\ "dasmen") do
    todays_date = Timex.format!(AppCount.current_time(), "{YYYY}-{0M}-{D}")

    from(
      c in Maintenance.CardItem,
      select: %{
        card_id: c.card_id,
        tech_id: c.tech_id,
        notes: c.notes,
        name: c.name,
        id: c.id,
        scheduled: c.scheduled
      },
      where: c.scheduled == ^todays_date and not is_nil(c.tech_id)
    )
    |> Repo.all(prefix: schema)
    |> Enum.each(fn c -> assign_tech_today(c, c.tech_id) end)
  end

  defp assign_tech_today(item, tech_id) do
    order = Repo.get_by(Maintenance.Order, card_item_id: item.id) || create_item_order(item)

    case from(
           a in Maintenance.Assignment,
           where: a.order_id == ^order.id and a.status in ["pending", "in_progress"],
           limit: 1,
           order_by: [
             asc: :updated_at
           ]
         )
         |> Repo.one() do
      nil ->
        Maintenance.assign_order(order.id, tech_id, nil)

      assignment ->
        assignment
        |> Maintenance.Assignment.changeset(%{
          tech_id: tech_id,
          confirmed_at: DateTime.utc_now(),
          status: "on_hold"
        })
        |> Repo.update!()
        |> Maintenance.Utils.Assignments.update_order_status("assigned", order.id)
    end
  end

  defp create_item_order(item) do
    card =
      Repo.get(Maintenance.Card, item.card_id)
      |> Repo.preload(:unit)

    admin = Repo.get_by(AppCount.Admins.Admin, name: card.admin)

    if admin do
      # TODO:SCHEMA remove the static
      params = %{
        unit_id: card.unit_id,
        property_id: card.unit.property_id,
        category_id: category_id_for(item),
        has_pet: false,
        entry_allowed: true,
        ticket: "0000000000",
        priority: 1,
        card_item_id: item.id,
        uuid: UUID.uuid4(),
        note: item.notes,
        admin_id: admin.id
      }

      {:ok, order} = Maintenance.create_order({"dasmen", params})
      order
    end
  end

  defp category_id_for(item) do
    from(
      c in Maintenance.Category,
      join: sc in assoc(c, :parent),
      where: sc.name == "Make Ready" and c.name == ^item.name,
      select: %{
        id: c.id
      }
    )
    |> Repo.one()
    |> case do
      nil ->
        {:ok, %{id: cat_id}} =
          Maintenance.create_category(%{
            "name" => item.name,
            "visible" => false,
            "path" => [card_item_tl_category_id()]
          })

        cat_id

      %{id: id} ->
        id
    end
  end

  defp card_item_tl_category_id() do
    Repo.get_by(Maintenance.Category, name: "Make Ready")
    |> case do
      nil ->
        {:ok, %{id: id}} = Maintenance.create_category(%{name: "Make Ready", visible: false})
        id

      %{id: id} ->
        id
    end
  end
end
