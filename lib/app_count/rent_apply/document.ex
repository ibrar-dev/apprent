defmodule AppCount.RentApply.Document do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.RentApply.Document
  use AppCount.EctoTypes.Attachment
  @behaviour AppCount.RentApply.ValidatableBehaviour

  schema "rent_apply__documents" do
    field(:type, :string)
    attachment(:url)

    belongs_to(:application, AppCount.RentApply.RentApplication, foreign_key: :application_id)

    timestamps()
  end

  @impl AppCount.RentApply.ValidatableBehaviour
  def validation_changeset(changeset, attrs) do
    changeset
    |> cast(attrs, [:type])
    |> cast_attachment(:url)
    |> validate_required([:type])
  end

  @doc false
  def changeset(%Document{} = document, attrs) do
    document
    |> validation_changeset(attrs)
    |> cast(attrs, [:application_id])
    |> validate_required([:application_id])
  end
end
