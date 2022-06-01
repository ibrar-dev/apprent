defmodule AppCount.Maintenance.Card do
  @moduledoc """
  A Card wraps a task list for getting a unit "ready" for move-in.

  Each card has many "Items", each of which is a single task for making a unit
  ready (e.g. painting, cleaning the carpets, etc.)

  Cards can be prioritized.

  A card's completion is either nil or a map like this:

  %{
    date: "ISO-8601 date string",
    name: "Some Admin's Name"
  }

  Presence of this map indicates the card is complete. Absence indicates that it
  is not complete.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Maintenance.Card

  schema "maintenance__cards" do
    field :admin, :string
    field :bypass_admin, :string
    field :bypass_date, :naive_datetime
    field :completion, :map
    field :deadline, :date
    field :hidden, :boolean, default: false
    field :move_in_date, :date
    field :move_out_date, :date
    field :priority, :integer

    has_many :items, AppCount.Maintenance.CardItem
    belongs_to :unit, AppCount.Properties.Unit

    timestamps()
  end

  @doc false
  def changeset(card, attrs) do
    card
    |> cast(attrs, [
      :admin,
      :bypass_admin,
      :bypass_date,
      :completion,
      :deadline,
      :hidden,
      :move_in_date,
      :move_out_date,
      :priority,
      :unit_id
    ])
    |> validate_required([:hidden, :move_out_date, :admin])
  end

  def end_date(%Card{completion: completion}) do
    {:ok, end_time} = completion["date"] |> Timex.parse("{ISO:Extended}")
    end_time
  end
end
