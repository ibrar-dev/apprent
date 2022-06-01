defmodule AppCount.Admins.Admin do
  @moduledoc """

  E-R diagram is like:
  Admin --< Permission >--- Region ---< Scoping  >-- Property

  """
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Admins.Auth.Authentication
  alias AppCount.Admins.Admin
  alias AppCount.Core.SchemaHelper

  @derive {Jason.Encoder,
           only: [
             :name
           ]}

  @valid_roles ["Admin", "Super Admin", "Agent", "Regional", "Accountant", "Tech", "Property"]

  schema "admins__admins" do
    field(:name, :string)
    field(:email, :string)
    field(:username, :string)
    field(:password, :string, virtual: true)
    field(:password_hash, :string)
    field(:uuid, Ecto.UUID)
    field(:roles, AppCount.EctoTypes.StringSet)
    field(:reset_pw, :boolean)
    field(:aggregate, :boolean, virtual: true, default: false)
    field(:active, :boolean, default: true)
    field(:is_super_admin, :boolean)
    has_one(:profile, AppCount.Admins.Profile)
    has_many(:permissions, AppCount.Admins.Permission)
    has_many(:prospects, AppCount.Prospects.Prospect)
    has_many(:email_subscriptions, AppCount.Admins.EmailSubscription)

    has_many(:admin_roles, AppCount.Admins.AdminRole)
    many_to_many(:custom_roles, AppCount.Admins.Role, join_through: AppCount.Admins.AdminRole)

    many_to_many(
      :regions,
      AppCount.Admins.Region,
      join_through: AppCount.Admins.Permission
    )

    belongs_to :public_user, AppCount.Public.User
    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    params =
      params
      |> crypt_password()
      |> SchemaHelper.cleanup_email()

    struct
    |> cast(params, [
      :name,
      :email,
      :username,
      :password_hash,
      :roles,
      :reset_pw,
      :active,
      :uuid,
      :public_user_id,
      :is_super_admin
    ])
    |> validate_required([:name, :email, :username])
    |> unique_constraint(:username)
    |> unique_constraint(:email)
  end

  def properties(%{aggregate: true} = admin) do
    admin.permissions
    |> Enum.map(fn permission -> permission.region.scopings end)
    |> List.flatten()
    |> Enum.map(fn scoping -> scoping.property end)
    |> Enum.filter(fn property -> active?(property.setting) end)
  end

  defp active?(nil) do
    false
  end

  defp active?(setting) do
    setting.active
  end

  def crypt_password(%{"password" => pwd} = params) when is_binary(pwd) and byte_size(pwd) > 7 do
    Map.merge(params, %{"password_hash" => Authentication.crypt_password(pwd)})
  end

  def crypt_password(%{password: pwd} = params) do
    Map.merge(params, %{password_hash: Authentication.crypt_password(pwd)})
  end

  def crypt_password(%{} = params), do: params

  def valid_roles do
    @valid_roles
  end

  def put_super_admin(%Admin{} = admin) do
    put_role(admin, "Super Admin")
  end

  def is_super_admin?(%Admin{} = admin) do
    has_role?(admin, "Super Admin")
  end

  def put_admin(%Admin{} = admin) do
    put_role(admin, "Admin")
  end

  def is_admin?(%Admin{} = admin) do
    has_role?(admin, "Admin")
  end

  def put_regional(%Admin{} = admin) do
    put_role(admin, "Regional")
  end

  def is_regional?(%Admin{} = admin) do
    has_role?(admin, "Regional")
  end

  def put_role(%Admin{roles: nil} = admin, role_name) do
    %{admin | roles: MapSet.new()}
    |> put_role(role_name)
  end

  def put_role(%Admin{roles: %MapSet{} = roles} = admin, role_name)
      when role_name in @valid_roles do
    roles = MapSet.put(roles, role_name)
    %{admin | roles: roles}
  end

  def has_role?(%Admin{roles: %MapSet{} = roles}, role_name) do
    MapSet.member?(roles, role_name)
  end

  def has_role?(%Admin{}, _role_name) do
    false
  end

  def permitted?(%Admin{roles: %MapSet{}, aggregate: true} = admin, property) do
    if has_role?(admin, "Super Admin") do
      true
    else
      admin = AppCount.Repo.preload(admin, permissions: [region: :scopings])
      # Entity Relationship diagram:
      # Admin --< Permission >--- Region ---< Scoping  >-- Property
      #
      # if admin has any connect properties then admin is 'permitted?' is true

      result =
        Enum.reduce(admin.permissions, :not_found, fn
          _permision, :found ->
            :found

          permision, :not_found ->
            scoping_has_property(permision.region.scopings, property)
        end)

      result == :found
    end
  end

  def permitted?(%Admin{}, _property) do
    false
  end

  defp scoping_has_property(scopings, property) do
    scopings
    |> Enum.reduce(:not_found, fn
      _scoping, :found ->
        :found

      scoping, :not_found ->
        if scoping.property_id == property.id do
          :found
        else
          :not_found
        end
    end)
  end
end
