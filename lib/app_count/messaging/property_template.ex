defmodule AppCount.Messaging.PropertyTemplate do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messaging__property_templates" do
    belongs_to :property, Module.concat(["AppCount.Properties.Property"])
    belongs_to :template, Module.concat(["AppCount.Messaging.MailTemplate"])

    timestamps()
  end

  @doc false
  def changeset(property_template, attrs) do
    property_template
    |> cast(attrs, [:property_id, :template_id])
    |> validate_required([:property_id, :template_id])
    |> unique_constraint(:property_id_number,
      name: :messaging__property_templates_property_id_index
    )
    |> unique_constraint(:template_id_number,
      name: :messaging__property_templates_template_id_index
    )
  end
end
