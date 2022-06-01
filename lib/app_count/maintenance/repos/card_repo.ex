defmodule AppCount.Maintenance.CardRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Maintenance.Card,
    preloads: [unit: [:property]]

  import Ecto.Query

  alias AppCount.Maintenance.Card
  alias AppCount.Repo
  alias AppCount.Maintenance.CardRepo
  alias AppCount.Core.DomainEventRepo

  def list_last_domain_event(card_ids) do
    last_event =
      DomainEventRepo.load_last_subjects(Card, card_ids)
      |> List.first()

    case last_event do
      nil ->
        {:ok, %{}}

      _ ->
        card = CardRepo.get_aggregate(last_event.subject_id)

        {
          :ok,
          %{
            subject_id: card.id,
            name: last_event.name,
            inserted_at: last_event.inserted_at,
            unit_number: card.unit.number,
            property_name: card.unit.property.name,
            admin_name: card.admin
          }
        }
    end
  end
end
