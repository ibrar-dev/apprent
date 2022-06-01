defmodule AppCountWeb.API.CardView do
  use AppCountWeb, :view

  def render("index.json", %{leases: leases}) do
    render_many(leases, __MODULE__, "lease.json", as: :lease)
  end

  def render("lease.json", %{lease: lease}) do
    %{
      id: lease.id,
      property_name: lease.unit.property.name,
      unit_number: lease.unit.number,
      move_out_date: lease.move_out_date,
      expected_move_in: lease.expected_move_in,
      card: card(lease.card)
    }
  end

  defp card(nil), do: nil

  defp card(card) do
    %{
      id: card.id,
      items: card.items,
      deadline: card.deadline
    }
  end
end
