defmodule AppCount.Public.Accounts do
  @moduledoc """
  The Public context.
  """

  import Ecto.Query, warn: false
  alias AppCount.Repo

  alias AppCount.Public.User

  @doc """
  Returns the list of User.

  ## Examples

      iex> list_user()
      [%User{}, ...]

  """
  def list_users do
    Repo.all(User, prefix: "public")
  end

  @doc """
  Gets a single User.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id) do
    Repo.get!(User, id, prefix: "public") |> Repo.preload([:client], prefix: "public")
  end

  def get_user_by_username(username) do
    Repo.get_by(User, [username: username], prefix: "public")
  end

  def get_user_by_email(email) do
    Repo.get_by(User, [email: email], prefix: "public")
  end

  def get_user_by_tenant_account(user_id, tenant_account_id) do
    Repo.get_by(User, [tenant_account_id: tenant_account_id, id: user_id], prefix: "public")
    |> Repo.preload([:client], prefix: "public")
  end

  def get_admin_by_tenant_account_id(tenant_account_id, schema) do
    client = AppCount.Public.get_client_by_schema(schema)

    Repo.get_by(User, [tenant_account_id: tenant_account_id, type: "Admin", client_id: client.id],
      prefix: "public"
    )
    |> Repo.preload([:client], prefix: "public")
  end

  def get_user_by_account(%AppCount.Accounts.Account{id: id} = account) do
    schema = account.__meta__.prefix

    client = AppCount.Public.get_client_by_schema(schema)

    from(user in User,
      where:
        user.tenant_account_id == ^id and user.type == "Tenant" and user.client_id == ^client.id,
      limit: 1
    )
    |> Repo.one(prefix: "public")
  end

  @doc """
  It is possible, though unlikely, that we will have an
  AppCount.Accounts.Account record without a corresponding AppCount.Public.User
  record.

  In this event, we want to create a new User record.

  We have no way of extracting password from the Account, so we randomize the
  password.
  """
  def create_user_from_account(%AppCount.Accounts.Account{} = account) do
    schema = account.__meta__.prefix

    client = AppCount.Public.get_client_by_schema(schema)

    %{
      client_id: client.id,
      type: "Tenant",
      tenant_account_id: account.id,
      username: account.username,
      password: UUID.uuid4()
    }
    |> create_user()
  end

  @doc """
  Creates a User.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert(prefix: "public")
  end

  @doc """
  Creates a User.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def create_app_rent_user(attrs \\ %{}) do
    client = AppCount.Public.get_client_by_schema("dasmen")

    %User{}
    |> User.app_rent_changeset(
      Map.merge(attrs, %{
        type: "AppRent",
        tenant_account_id: 0,
        client_id: client.id
      })
    )
    |> Repo.insert(prefix: "public")
  end

  @doc """
  Creates a User Sync.

  ## Examples

      iex> create_user_sync(%{field: value})
      {:ok, %User{}}

      iex> create_user_sync(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user_sync(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert(prefix: "public")
  end

  @doc """
  Updates a User.

  ## Examples

      iex> update_user(User, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(User, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update(prefix: "public")
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking User changes.

  ## Examples

      iex> change_user(User)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  def unique_username(suggested_username, type, integer_suffix \\ 0) do
    if Repo.get_by(User, [username: suggested_username, type: type], prefix: "public") do
      new_suffix = integer_suffix + 1
      unique_username("#{suggested_username}#{new_suffix}", type, new_suffix)
    else
      suggested_username
    end
  end
end
