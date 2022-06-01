defmodule AppCount.PublicTest do
  use AppCount.DataCase
  # doctest
  alias AppCount.Public

  describe "clients" do
    setup do
      {:ok, client: client_fixture()}
    end

    alias AppCount.Public.Client

    @valid_attrs %{features: %{}, name: "client1", client_schema: "moli", status: "active"}

    @update_attrs %{
      features: %{},
      name: "updated Client",
      client_schema: "moli",
      status: "active"
    }

    @invalid_attrs %{features: nil, name: nil, client_schema: nil}

    def client_fixture(attrs \\ %{}) do
      attrs
      |> Enum.into(@valid_attrs)
      |> Public.create_client(create_schema: false)
    end

    test "new_client_with_admin/1 create new client with admin" do
      random = Enum.random(100..1000)

      %{
        features: %{},
        name: "molka#{random}",
        schema: "molka#{random}",
        status: "active",
        admin: %{
          email: "imo@rieruer.com",
          name: "Imo#{random}",
          password: "paragon",
          roles: ["Super Admin"],
          username: "admin#{random}"
        }
      }
      |> AppCount.Public.new_client_with_admin(create_schema: false)
    end

    test "list_clients/0 returns all clients", state do
      {:ok, client} = state[:client]

      assert Enum.find(
               Public.list_clients(),
               &(Map.take(&1, [:id, :name, :schema]) == Map.take(client, [:id, :name, :schema]))
             )
    end

    test "get_client!/1 returns the client with given id", state do
      {:ok, client} = state[:client]
      assert Public.get_client!(client.id) == client
    end

    test "create_client/1 with valid data creates a client", state do
      assert {:ok, %Client{} = client} = state[:client]
      assert client.name == "client1"
      assert client.client_schema == "moli"
    end

    test "create_client/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Public.create_client(@invalid_attrs)
    end

    test "update_client/2 with invalid data returns error changeset", state do
      {:ok, client} = state[:client]
      assert {:error, %Ecto.Changeset{}} = Public.update_client(client, @invalid_attrs)
      assert client == Public.get_client!(client.id)
    end

    test "update_client/2 with valid data updates the client", state do
      {:ok, client} = state[:client]
      assert {:ok, %Client{} = client} = Public.update_client(client, @update_attrs)
      assert client.name == "updated Client"
      assert client.client_schema == "moli"
    end

    test "deactivate_client/2 with valid client", state do
      {:ok, client} = state[:client]

      assert {:ok, %Client{} = client} = Public.deactivate_client(client)
      assert client.status == "deactivated"
    end

    test "delete_client/1 deletes the client", state do
      {:ok, client} = state[:client]
      assert {:ok, %Client{}} = Public.delete_client(client)
      assert_raise Ecto.NoResultsError, fn -> Public.get_client!(client.id) end
    end

    test "change_client/1 returns a client changeset", state do
      {:ok, client} = state[:client]
      assert %Ecto.Changeset{} = Public.change_client(client)
    end
  end
end
