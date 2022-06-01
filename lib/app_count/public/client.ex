defmodule AppCount.Public.Client do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "public"
  schema "clients" do
    field(:name, :string)
    field(:status, :string)
    field(:client_schema, :string)

    has_many(:users, AppCount.Public.User)
    has_many(:client_modules, AppCount.Public.ClientModule, on_replace: :delete)
    timestamps()

    # used in new client validator
    has_one(:user, AppCount.Public.User)
  end

  @doc false
  def changeset(client, attrs) do
    client
    |> cast(attrs, [:name, :client_schema, :status])
    |> slug_schema()
    |> validate_required([:name, :client_schema])
    |> unique_constraint(:name, name: :clients_name_index)
    |> unique_constraint(:schema, name: :clients_schema_index)
    |> cast_assoc(:client_modules, with: &AppCount.Public.ClientModule.assoc_changeset/2)
    |> validate_features()
  end

  def create_changeset_validator(client, attrs) do
    changeset(client, attrs)
    |> cast(attrs, [:name, :client_schema, :status])
    |> slug_schema()
    |> validate_required([:name, :client_schema])
    |> unique_constraint(:name, name: :clients_name_index)
    |> unique_constraint(:client_schema, name: :clients_client_schema_index)
    |> cast_assoc(
      :users,
      with: &AppCount.Public.User.new_tenant_admin_validator/2
    )
  end

  @doc """
  Update Changeset
  """
  def update_changeset(client, attrs) do
    client
    |> cast(attrs, [:name, :status])
    |> validate_required([:name])
    |> cast_assoc(:client_modules, with: &AppCount.Public.ClientModule.assoc_changeset/2)
    |> validate_features
    |> unique_constraint(:name, name: :clients_name_index)
  end

  def slug_schema(%Ecto.Changeset{changes: %{client_schema: schema}} = changeset) do
    put_change(changeset, :client_schema, Slug.slugify(schema, separator: ?_))
  end

  def slug_schema(changeset) do
    changeset
  end

  def validate_features(changeset) do
    applied =
      get_field(changeset, :client_modules)
      |> Enum.map(&Map.take(&1, [:module_id, :enabled]))

    default_feature_attrs =
      AppCountAuth.ModuleRepo.list()
      |> Enum.map(&Map.take(&1, [:name, :id]))
      |> Enum.filter(&(&1.name != "Core"))
      |> Enum.map(&%{module_id: &1.id, enabled: false})

    full_feature_list =
      Enum.reduce(
        default_feature_attrs,
        applied,
        fn default_attr, feature_list ->
          case Enum.find(applied, &(&1.module_id == default_attr.module_id)) do
            nil ->
              feature_list ++ [default_attr]

            _ ->
              feature_list
          end
        end
      )

    put_assoc(changeset, :client_modules, full_feature_list)
  end
end
