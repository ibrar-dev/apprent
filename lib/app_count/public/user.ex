defmodule AppCount.Public.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:type, :string)
    field(:username, :string)
    field(:password, :string, virtual: true)
    field(:password_hash, :string)
    field(:tenant_account_id, :integer)

    # required in schema admin table
    field(:email, :string, virtual: true)
    field(:name, :string, virtual: true)
    field(:roles, AppCount.EctoTypes.StringSet, virtual: true)

    belongs_to(:client, AppCount.Public.Client)

    timestamps()
  end

  @doc false
  def changeset(users, attrs) do
    users
    |> cast(attrs, [
      :type,
      :username,
      :client_id,
      :password,
      :tenant_account_id,
      :password_hash
    ])
    |> put_password_hash()
    |> validate_required([
      :type,
      :username,
      :tenant_account_id,
      :client_id,
      :password_hash
    ])
    |> unique_constraint(:username, name: :users_username_type_index)
  end

  def app_rent_changeset(users, attrs) do
    users
    |> cast(attrs, [
      :type,
      :username,
      :tenant_account_id,
      :password,
      :client_id
    ])
    |> put_password_hash()
    |> validate_required([
      :type,
      :username,
      :password_hash
    ])
    |> unique_constraint(:username, name: :users_username_type_index)
  end

  @doc """
  Validate New Tenant Admin Account
  """
  def new_tenant_admin_validator(users, attrs) do
    users
    |> cast(attrs, [
      :type,
      :username,
      :password,
      :password,
      :name,
      :email,
      :roles
    ])
    |> put_defualt_type()
    |> put_new_tenant_admin_roles()
    |> validate_required([
      :type,
      :username,
      :password,
      :name,
      :email,
      :roles
    ])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:username, name: :users_username_type_index)
    |> validate_username()
  end

  def put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: nil}} = changeset) do
    changeset
  end

  def put_password_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    put_change(changeset, :password_hash, Bcrypt.hash_pwd_salt(password))
  end

  def put_password_hash(changeset) do
    changeset
  end

  def validate_username(%Ecto.Changeset{valid?: true, changes: %{username: username}} = changeset) do
    case AppCount.Public.Accounts.get_user_by_username(username) do
      nil ->
        changeset

      _user ->
        changeset
        |> add_error(:username, "has already been taken")
    end
  end

  def validate_username(changeset) do
    changeset
  end

  def put_defualt_type(changeset) do
    put_change(changeset, :type, "Admin")
  end

  def put_new_tenant_admin_roles(changeset) do
    put_change(changeset, :roles, ["Super Admin"])
  end
end
