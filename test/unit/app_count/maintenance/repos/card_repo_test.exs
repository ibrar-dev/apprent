defmodule AppCount.Maintenance.CardRepoTest do
  use AppCount.DataCase
  alias AppCount.Maintenance.CardRepo
  alias AppCount.Core.DomainEventRepo

  describe "card in DB" do
    setup do
      card =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card()
        |> PropBuilder.get_requirement(:card)

      ~M[card]
    end

    test "get card from id", ~M[card] do
      assert CardRepo.get(card.id)
    end

    test "get_aggregate()", ~M[card] do
      full_card = CardRepo.get_aggregate(card.id)
      assert Ecto.assoc_loaded?(full_card.unit)
      assert Ecto.assoc_loaded?(full_card.unit.property)
    end
  end

  describe "list_last_domain_event/1" do
    setup do
      card =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_card()
        |> PropBuilder.get_requirement(:card)

      ~M[card]
    end

    test "with no domain events", ~M[card] do
      assert CardRepo.list_last_domain_event([card.id]) == {:ok, %{}}
    end

    test "with no card_ids" do
      result = CardRepo.list_last_domain_event([])
      assert result == {:ok, %{}}
    end

    test "with card_ids and a domain event", ~M[card] do
      domain_event = AppCount.Maintenance.Utils.CardPublisher.publish_card_created_event(card.id)
      DomainEventRepo.store(domain_event)
      # When
      {:ok, event} = CardRepo.list_last_domain_event([card.id])
      assert event[:subject_id] == card.id
    end
  end
end
