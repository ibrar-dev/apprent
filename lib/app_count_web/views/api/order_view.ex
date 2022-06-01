defmodule AppCountWeb.API.OrderView do
  use AppCountWeb, :view
  alias AppCount.Maintenance.Order
  alias AppCount.Maintenance.Note

  def render("index.json", %{orders: orders}) do
    render_many(orders, __MODULE__, "order.json")
  end

  def render("order.json", %{order: order}) do
    current_assignment = Order.current_assignment(order)

    %{
      id: order.id,
      tenant: "#{order.tenant.first_name} #{order.tenant.last_name}",
      submitted: order.inserted_at,
      assigned_to: current_assignment && current_assignment.tech.name,
      status: status(current_assignment),
      has_pet: order.has_pet,
      entry_allowed: order.entry_allowed,
      priority: order.priority,
      notes: Enum.map(order.notes, &note/1),
      assignments: Enum.map(order.assignments, &assignment/1),
      # offers: Enum.map(order.offers, &offer/1),
      property_id: order.unit.property_id,
      unit: order.unit.number,
      cancellation: order.cancellation,
      property: %{
        id: order.unit.property_id,
        name: order.unit.property.name,
        lat: Decimal.to_float(order.unit.property.lat || Decimal.new(0)),
        lng: Decimal.to_float(order.unit.property.lng || Decimal.new(0))
      },
      category: "#{order.category.parent.name} > #{order.category.name}",
      category_id: order.category_id
    }
  end

  def assignment(a) do
    %{
      id: a.id,
      status: a.status,
      tech: a.tech.name,
      tech_id: a.tech_id,
      materials: a.materials,
      rating: a.rating,
      tech_comments: a.tech_comments,
      confirmed_at: a.confirmed_at,
      completed_at: a.completed_at,
      updated_at: a.updated_at
    }
  end

  def offer(o) do
    %{
      id: o.id,
      tech_id: o.tech_id
    }
  end

  def note(note) do
    %{
      id: note.id,
      text: note.text,
      admin: note.admin && note.admin.name,
      tenant: note.tenant && "#{note.tenant.first_name} #{note.tenant.last_name}",
      image: Note.image_url(note)
    }
  end

  def status(nil), do: "open"
  def status(%{status: "callback"}), do: "open"
  def status(%{status: "rejected"}), do: "open"
  def status(%{status: "withdrawn"}), do: "open"
  def status(%{status: "revoked"}), do: "open"
  def status(%{status: s}), do: s
end
