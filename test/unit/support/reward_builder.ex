defmodule AppCount.Support.RewardBuilder do
  alias AppCount.Support.RewardBuilder, as: Builder
  alias AppCount.Properties.Property
  alias AppCount.Tenants.TenantRepo
  alias AppCount.Tenants.RewardTenantRepo
  alias AppCount.Rewards.Accomplishment
  alias AppCount.Rewards.Type
  alias AppCount.Rewards.Reward
  alias AppCount.Repo
  alias AppCount.Rewards.Purchase

  defstruct req: %{}, sequence_num: nil, mode: :build
  @top 100_000_000

  def new(mode) when mode in [:build, :create] do
    %Builder{
      mode: mode,
      sequence_num: Enum.random(1..@top)
    }
  end

  def add_purchase(
        %Builder{req: %{tenant: tenant, reward: reward, property: property}} = builder,
        extra \\ []
      ) do
    purchase =
      %Purchase{
        points: 50,
        status: "pending"
      }
      |> put_association(:tenant, tenant, builder)
      |> put_association(:reward, reward, builder)
      |> put_association(:property, property, builder)

    {:ok, purchase} = create(builder, purchase, extra)

    builder
    |> put_requirement(:purchase, purchase)
  end

  def add_reward(%Builder{} = builder, extra \\ []) do
    {type_number, builder} = sequence(builder)

    reward = %Reward{
      name: "reward-#{type_number}",
      points: 50
    }

    {:ok, reward} = create(builder, reward, extra)

    builder
    |> put_requirement(:reward, reward)
  end

  def add_type(%Builder{} = builder, extra \\ []) do
    {type_number, builder} = sequence(builder)

    type = %Type{
      name: "type-#{type_number}",
      points: 50,
      active: true,
      monthly_max: 30
    }

    {:ok, type} = create(builder, type, extra)

    builder
    |> put_requirement(:type, type)
  end

  def add_accomplishment(%Builder{req: %{tenant: tenant, type: type}} = builder, extra \\ []) do
    # too restrictive:
    # AccomplishmentRepo.create_accomplishment(%{tenant_id: tenant.id, type: type.name})
    accomplishment =
      %Accomplishment{
        tenant_id: tenant.id,
        amount: 50,
        reason: "Because I said so",
        created_by: "Jose"
      }
      |> put_association(:type, type, builder)

    {:ok, accomplishment} = create(builder, accomplishment, extra)

    builder
    |> put_requirement(:accomplishment, accomplishment)
  end

  def add_tenant(%Builder{} = builder, _extra \\ []) do
    {tenant_number, builder} = sequence(builder)

    tenant_attrs = %{
      first_name: "First#{tenant_number}",
      last_name: "Last#{tenant_number}",
      email: "someguy#{tenant_number}@yahoo.com",
      uuid: UUID.uuid4()
    }

    {:ok, tenant} = TenantRepo.insert(tenant_attrs)
    reward_tenant = RewardTenantRepo.get_aggregate(tenant.id)

    builder
    |> put_requirement(:tenant, reward_tenant)
  end

  def add_property(%Builder{} = builder, extra \\ []) do
    {code_num, builder} = sequence(builder)

    property = %Property{
      name: "Test Property-#{code_num}",
      code: "prop-#{code_num}",
      address: %{
        zip: "28205",
        street: "3317 Magnolia Hill Dr",
        state: "NC",
        city: "Charlotte"
      },
      terms: "These are my terms, take 'em or leave 'em",
      social: %{}
    }

    {:ok, property} = create(builder, property, extra)
    put_requirement(builder, :property, property)
  end

  # --------------------------------------------------------
  # Private
  # --------------------------------------------------------
  def get_requirement(%Builder{req: req, mode: :create}, :property) do
    property = Map.fetch!(req, :property)
    AppCount.Properties.PropertyRepo.get_aggregate(property.id)
  end

  def get_requirement(%Builder{req: req}, name) do
    Map.get(req, name, "#{name} Not Found")
  end

  def get(%Builder{req: req} = builder, name) do
    req = Map.get(req, name, "#{name} Not Found")
    {builder, req}
  end

  def put_requirement(%Builder{req: req} = builder, name, value) do
    req = Map.put(req, name, value)
    %{builder | req: req}
  end

  defp sequence(%Builder{sequence_num: sequence_num} = builder) do
    builder = %{builder | sequence_num: sequence_num + 1}
    {sequence_num, builder}
  end

  defp create(%Builder{mode: :build}, schema, extra) do
    {:ok, schema |> merge(extra)}
  end

  defp create(%Builder{mode: :create}, %module_name{} = schema, extra) do
    schema
    |> merge(extra)
    |> module_name.changeset(%{})
    |> Repo.insert()
  end

  defp put_association(target, association_name, association_struct, %Builder{mode: :create}) do
    association_name = "#{association_name}_id" |> String.to_atom()

    target
    |> Map.put(association_name, association_struct.id)
  end

  defp put_association(target, association_name, association_struct, %Builder{mode: :build}) do
    target
    |> Map.put(association_name, association_struct)
  end

  defp merge(struct, extra_as_keyword_list) do
    Map.merge(struct, Map.new(extra_as_keyword_list))
  end
end
