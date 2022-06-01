defmodule AppCount.Properties.LetterTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "properties__letter_templates" do
    field :name, :string
    field :body, :string
    belongs_to :property, Module.concat(["AppCount.Properties.Property"])
    has_many :recurring_letters, Module.concat(["AppCount.Properties.RecurringLetter"])

    timestamps()
  end

  @doc false
  def changeset(letter_template, attrs) do
    letter_template
    |> cast(attrs, [:name, :body, :property_id])
    |> validate_required([:name, :body, :property_id])
  end
end
