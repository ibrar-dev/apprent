defmodule AppCount.Public do
  @moduledoc """
  The Public context.
  """

  import Ecto.Query, warn: false
  alias AppCount.Repo
  alias Ecto.Multi
  alias AppCount.Public.Client
  alias AppCount.Public.ClientModule
  alias AppCount.Core.ClientSchema

  @doc """
  Returns the list of clients.

  ## Examples

      iex> list_clients()
      [%Client{}, ...]

  """
  def list_clients do
    Repo.all(Client, prefix: "public")
  end

  def list_active_clients do
    query = from(c in Client, where: c.status == "active")
    Repo.all(query, prefix: "public")
  end

  @doc """
  Gets a single client.

  Raises `Ecto.NoResultsError` if the Client does not exist.

  ## Examples

      iex> get_client('dasmen')
      %Client{}

      iex> get_client('dasmen')
      ** (Ecto.NoResultsError)

  """
  def get_client(name) do
    Repo.get_by(Client, name: name)
  end

  @doc """
  Gets a single client.

  Raises `Ecto.NoResultsError` if the Client does not exist.

  ## Examples

      iex> get_client!(123)
      %Client{}

      iex> get_client!(456)
      ** (Ecto.NoResultsError)

  """
  def get_client!(id) do
    Repo.get!(Client, id, prefix: "public")
    |> Repo.preload(:client_modules, prefix: "public")
  end

  def get_client_by_schema(schema),
    do: Repo.get_by(Client, [client_schema: schema], prefix: "public")

  @doc """
  Create Sample Tenant ( DO NOT USE THIS WITHIN THE APPLICATION )

  ## Examples

      iex> run_new_client(%{field: value})
      {:ok, %Client{}}

      iex> run_new_client(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  {:error, changeset}
  """
  def run_new_client() do
    random = Enum.random(100..1000)

    params = %{
      features: %{},
      name: "molka#{random}",
      client_schema: "molka#{random}",
      status: "active",
      admin: %{
        email: "imo@example#{random}.com",
        name: "Imo#{random}",
        password: "password",
        roles: ["Super Admin"],
        username: "admin#{random}"
      }
    }

    new_client_with_admin(params, create_schema: true)
  end

  def new_client_with_admin(%{admin: admin_params} = params, opts \\ [create_schema: true]) do
    case create_client(params, opts) do
      {:ok, client} ->
        Multi.new()
        |> Multi.run(
          :admin,
          fn _repo, _cs ->
            if opts[:create_schema] do
              AppCount.Admins.Utils.Admins.create_admin(
                ClientSchema.new(
                  client.client_schema,
                  Map.merge(admin_params, %{client_id: client.id})
                )
              )
            else
              {:ok, nil}
            end
          end
        )
        |> Repo.transaction()

      e ->
        e
    end
  end

  def create_client(attrs, opts \\ [create_schema: true]) do
    %Client{}
    |> Client.changeset(attrs)
    |> Repo.insert(prefix: "public")
    |> case do
      {:ok, client} ->
        # create tenant
        if opts[:create_schema] do
          with {:ok, _tenant} <- Triplex.create(client.client_schema),
               {:ok, _migrate} <- migrate_tenant(client.client_schema) do
            {:ok, client}
          else
            error ->
              # TODO probably should delete the client entry here if
              # the schema did not create or migrate properly
              error
          end
        else
          {:ok, client}
        end

      #
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a client.

  ## Examples

      iex> update_client(client, %{field: new_value})
      {:ok, %Client{}}

      iex> update_client(client, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_client(%Client{} = client, attrs) do
    client
    |> Client.update_changeset(attrs)
    |> Repo.update(prefix: "public")
  end

  @doc """
  Deactivate an client.

  ## Examples

      iex> deactivate_client(client)
      {:ok, %Client{}}

      iex> update_client(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """

  def deactivate_client(client) do
    client
    |> Client.update_changeset(%{status: "deactivated"})
    |> Repo.update(prefix: "public")
  end

  @doc """
  Deletes a client.

  ## Examples

      iex> delete_client(client)
      {:ok, %Client{}}

      iex> delete_client(client)
      {:error, %Ecto.Changeset{}}

  """
  def delete_client(%Client{} = client) do
    if Triplex.exists?(client.client_schema, Repo) do
      case Triplex.drop(client.client_schema) do
        {:ok, _migrate} ->
          Repo.delete(client, prefix: "public")

        {:error, changeset} ->
          {:error, changeset}
      end
    else
      Repo.delete(client, prefix: "public")
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking client changes.

  ## Examples

      iex> change_client(client)
      %Ecto.Changeset{data: %Client{}}

  """
  def change_client(%Client{} = client, attrs \\ %{}) do
    Client.changeset(client, attrs)
  end

  def edit_client(%Client{} = client, attrs \\ %{}) do
    Client.update_changeset(client, attrs)
  end

  def validate_client(%Client{} = client, attrs \\ %{}) do
    Client.create_changeset_validator(client, attrs)
  end

  def validated_client_to_map(changeset) do
    # Get First
    admin = List.first(changeset.changes.users).changes

    changeset.changes
    |> update_in(
      [:client_modules],
      &Enum.map(&1, fn cs -> Map.take(cs.changes, [:enabled, :module_id]) end)
    )
    |> Map.put(:admin, admin)
    |> Map.delete(:users)
    |> Map.put(:status, "active")
  end

  def create_client_feature(attrs \\ %{}) do
    %ClientModule{}
    |> ClientModule.changeset(attrs)
    |> Repo.insert(prefix: "public")
  end

  def migrate_tenant(tenant) do
    Triplex.migrate(tenant)
  end
end
