defmodule AppCount.Core.DomainEvent do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Core.DomainEvent
  @req_fields [:topic, :name, :content, :source]
  @optional_fields [:subject_name, :subject_id]
  @all_fields @req_fields ++ @optional_fields

  schema "core__domain_events" do
    field :topic, :string
    field :name, :string
    field :content, :string
    field :source, :string
    # may be blank
    field :subject_name, :string
    # may be blank
    field :subject_id, :integer
    timestamps(updated_at: false)
  end

  def createset(%DomainEvent{} = domain_event) do
    attrs = domain_event |> Map.from_struct()

    %DomainEvent{}
    |> cast(attrs, @all_fields)
    |> validate_required(@req_fields)
  end

  def unpack_content(%DomainEvent{content: binary_content} = domain_event) do
    content = binary_content |> Base.decode64!() |> :erlang.binary_to_term()
    %{domain_event | content: content}
  end

  def pack_content(%DomainEvent{content: term_content} = domain_event) do
    %{domain_event | content: term_content |> :erlang.term_to_binary() |> Base.encode64()}
  end

  def short_source(source) when is_atom(source) do
    source |> Atom.to_string() |> short_source()
  end

  def short_source(source) do
    source |> String.split(".") |> List.last()
  end
end
