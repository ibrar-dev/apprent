defmodule AppCount.Core.DomainEventRepo do
  import Ecto.Query
  alias AppCount.Core.DomainEvent
  alias AppCount.Repo
  require Logger

  def count do
    AppCount.Repo.count(AppCount.Core.DomainEvent)
  end

  def store(%DomainEvent{source: source, subject_name: subject_name} = domain_event) do
    insert_result =
      %{
        domain_event
        | source: to_string(source),
          subject_name: to_string(subject_name)
      }
      |> DomainEvent.pack_content()
      |> DomainEvent.createset()
      |> Repo.insert()

    case insert_result do
      {:ok, _domain_event} ->
        :ok

      error ->
        Logger.error("#{__MODULE__}.store ==> #{inspect(error)}")
        error
    end
  end

  def load_topic(topic) do
    from(
      d in DomainEvent,
      where: d.topic == ^topic,
      order_by: [:inserted_at, :id]
    )
    |> Repo.all()
    |> unpack_domain_events()
  end

  def load_subject(subject_name, subject_id) do
    subject_name = to_string(subject_name)

    from(
      d in DomainEvent,
      where: d.subject_name == ^subject_name,
      where: d.subject_id == ^subject_id,
      order_by: [:inserted_at, :id]
    )
    |> Repo.all()
    |> unpack_domain_events()
  end

  def load_last_subjects(subject_name, subject_ids, limit \\ 1) do
    subject_name = to_string(subject_name)

    from(
      d in DomainEvent,
      where: d.subject_name == ^subject_name,
      where: d.subject_id in ^subject_ids,
      order_by: [desc: :inserted_at, desc: :id],
      limit: ^limit
    )
    |> Repo.all()
    |> unpack_domain_events()
  end

  defp unpack_domain_events(domain_events) do
    domain_events
    |> Enum.map(fn domain_event -> DomainEvent.unpack_content(domain_event) end)
  end
end
