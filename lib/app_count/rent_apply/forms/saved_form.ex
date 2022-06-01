defmodule AppCount.RentApply.Forms.SavedForm do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.RentApply.Forms.SavedForm
  alias AppCount.Core.SchemaHelper

  schema "rent_apply__saved_forms" do
    field(:email, :string)
    field(:name, :string)
    field(:lang, :string)
    field(:crypted_form, :string)
    field(:start_time, :utc_datetime)
    field(:form_summary, :map)
    field(:form, :map, virtual: true)
    belongs_to(:property, AppCount.Properties.Property)

    timestamps()
  end

  @doc false
  def changeset(%SavedForm{} = saved_form, attrs) do
    attrs = SchemaHelper.cleanup_email(attrs)

    saved_form
    |> cast(attrs, [
      :email,
      :crypted_form,
      :property_id,
      :name,
      :form_summary,
      :lang,
      :start_time
    ])
    |> validate_required([:email, :crypted_form, :property_id])
    |> unique_constraint(:email, name: :saved_forms_email_property_id_index)
  end
end
