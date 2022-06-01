defmodule AppCount.Properties.Processor do
  use Ecto.Schema
  import Ecto.Changeset

  # type: lease, screening, cc, management, ba
  #
  # It appears that these (list below) are the only possible mappings.
  # {"cc", "Authorize"}, Credit Cards ALWAYS wse Authorize, etc.
  # the code makes this relationship hard to see.
  # for instance, the code makes it seem like Credit Cards _could_ use BlueMoon for processing
  # but that would be an error.
  # making these relationships mappable is confusing and could cause errors.
  #  ----
  #
  # {"cc", "Authorize"},
  # {"screening", "TenantSafe"},
  # {"management", "Yardi"},
  # {"lease", "BlueMoon"},
  # {"ba", "Payscape"}

  schema "properties__processors" do
    field :keys, {:array, AppCount.Crypto.LocalCryptedData}, default: []
    field :type, :string
    field :name, :string
    field :login, :string
    field :password, AppCount.Crypto.LocalCryptedData
    belongs_to :property, AppCount.Properties.Property

    timestamps()
  end

  @doc false
  def changeset(processor, attrs) do
    processor
    |> cast(attrs, [
      :name,
      :type,
      :property_id,
      :login,
      :password,
      :keys
    ])
    |> validate_required([:name, :keys, :type, :property_id])
    |> unique_constraint(:unique, name: :properties__processors_property_id_type_index)
  end
end
