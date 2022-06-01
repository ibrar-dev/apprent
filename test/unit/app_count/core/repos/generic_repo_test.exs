defmodule AppCount.Core.GenericRepoTest do
  @moduledoc """
  In order to test a GenericRepo we have to setup a Specific Repo which we call "RepoUnderTest"
  RepoUnderTest needs a data base schema for a table in the DB, so we setup one called "MiniSchema"
  """
  use AppCount.DataCase
  alias AppCount.Core.GenericRepoTest.RepoUnderTest
  alias AppCount.Core.GenericRepoTest.MiniSchema
  alias AppCount.Properties.Insurance
  @moduletag :generic_repo

  defmodule EchoTopic do
    @behaviour AppCount.Core.RepoTopicBehaviour
    @impl AppCount.Core.RepoTopicBehaviour
    def created(_meta, _source), do: send(self(), :created)

    @impl AppCount.Core.RepoTopicBehaviour
    def changed(meta, _source), do: send(self(), meta)

    @impl AppCount.Core.RepoTopicBehaviour
    def deleted(_meta, _source), do: send(self(), :deleted)
  end

  defmodule MiniSchema do
    use Ecto.Schema
    import Ecto.Changeset

    schema "tenants__tenants" do
      field(:first_name, :string)
      field(:last_name, :string)
      field(:uuid, Ecto.UUID)

      field(:aggregate, :boolean, virtual: true, default: false)
      has_one(:insurance, Insurance, foreign_key: :tenant_id)
      timestamps()
    end

    def changeset(struct, params \\ %{}) do
      struct
      |> cast(params, [:first_name, :last_name, :uuid])
      |> validate_required([:first_name, :last_name, :uuid])
    end
  end

  defmodule RepoUnderTest do
    use AppCount.Core.GenericRepo,
      schema: MiniSchema,
      preloads: [:insurance],
      topic: AppCount.Core.GenericRepoTest.EchoTopic
  end

  def attrs() do
    uuid = Ecto.UUID.generate()
    %{first_name: "Ringo", last_name: "Starr", uuid: uuid}
  end

  def insert_tenant do
    {:ok, tenant} = RepoUnderTest.insert(attrs())
    tenant
  end

  def insert_insurance(tenant) do
    insurance = %Insurance{
      tenant_id: tenant.id,
      company: "Giaco",
      begins: Clock.today(),
      ends: Clock.today(),
      amount: Decimal.new(0),
      number: "42"
    }

    {:ok, insurance} = AppCount.Repo.insert(insurance)
    insurance
  end

  test "insert/1 map" do
    {:ok, tenant} = RepoUnderTest.insert(attrs())
    assert tenant.id
    assert_receive :created
  end

  describe "MiniSchema exists" do
    setup do
      {:ok, tenant} = RepoUnderTest.insert(attrs())
      ~M[tenant]
    end

    test "update/2", ~M[tenant] do
      {:ok, tenant} = RepoUnderTest.update(tenant, %{first_name: "updated first name"})
      assert tenant.id
      tenant_id = tenant.id

      assert_receive %{
        changes: %{first_name: "updated first name"},
        subject_id: ^tenant_id,
        subject_name: AppCount.Core.GenericRepoTest.MiniSchema
      }
    end

    test "delete/1", ~M[tenant] do
      {:ok, tenant} = RepoUnderTest.delete(tenant.id)
      assert tenant.id
      assert_receive :deleted
    end
  end

  describe "aggregate/1" do
    test ":error" do
      {:error, message} = RepoUnderTest.aggregate(0)
      assert message == "Not Found Elixir.AppCount.Core.GenericRepoTest.MiniSchema id: 0"
    end

    test ":ok" do
      tenant = insert_tenant()
      {:ok, tenant} = RepoUnderTest.aggregate(tenant.id)

      assert tenant
      assert tenant.aggregate
    end
  end

  describe "all/0" do
    test "not_found" do
      # When
      tenants = RepoUnderTest.all()

      assert tenants == []
    end

    test "one tenant" do
      _tenant = insert_tenant()

      # When
      tenants = RepoUnderTest.all()

      assert length(tenants) == 1
    end
  end

  describe "get_aggregate/1" do
    test " not_found" do
      id = 0
      # When
      tenant_aggregate = RepoUnderTest.get_aggregate(id)

      assert tenant_aggregate == nil
    end

    test "sets aggregate flag" do
      tenant = insert_tenant()

      # When
      tenant_aggregate = RepoUnderTest.get_aggregate(tenant.id)

      assert tenant_aggregate.aggregate
    end

    test "preloads insurance" do
      tenant = insert_tenant()
      insurance = insert_insurance(tenant)

      # When
      tenant_aggregate = RepoUnderTest.get_aggregate(tenant.id)

      # Then
      assert Ecto.assoc_loaded?(tenant_aggregate.insurance)
      assert tenant_aggregate.insurance == insurance
    end
  end
end
