defmodule AppCount.Maintenance.CardItemRepoTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.CardItemRepo

  describe "card_item in DB" do
    setup do
      card_item =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card()
        |> PropBuilder.add_card_item()
        |> PropBuilder.get_requirement(:card_item)

      ~M[card_item]
    end

    test "get card_item from id", ~M[card_item] do
      assert CardItemRepo.get(card_item.id)
    end

    test "get_aggregate()", ~M[card_item] do
      full_card_item = CardItemRepo.get_aggregate(card_item.id)
      assert Ecto.assoc_loaded?(full_card_item.card)
      assert Ecto.assoc_loaded?(full_card_item.card.unit)
    end
  end
end
