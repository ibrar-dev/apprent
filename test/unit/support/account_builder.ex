defmodule AppCount.Support.AccountBuilder do
  alias AppCount.Support.AccountBuilder, as: Builder
  alias AppCount.Accounts.Account
  alias AppCount.Accounts.AccountRepo
  alias AppCount.Accounts.Autopay
  alias AppCount.Core.Clock
  alias AppCount.Repo

  defstruct req: %{}, sequence_num: nil, mode: :build
  @top 100_000_000

  def new(mode) when mode in [:build, :create] do
    %Builder{
      mode: mode,
      sequence_num: Enum.random(1..@top)
    }
  end

  def add_account(%Builder{req: %{tenant: tenant, property: property}} = builder, _extra \\ []) do
    account_attrs = %{
      tenant_id: tenant.id,
      username: "user381",
      property_id: property.id,
      password: "password",
      encrypted_password: Bcrypt.hash_pwd_salt("password"),
      uuid: UUID.uuid4()
    }

    full_account_params =
      account_attrs
      |> Account.new()
      |> Map.from_struct()

    {:ok, account} = AccountRepo.insert(full_account_params)

    builder
    |> put_requirement(:account, account)
  end

  def add_payment_source(%Builder{req: %{account: account}} = builder, extra \\ []) do
    {unique_number, builder} = sequence(builder)

    payment_source_attrs = %{
      type: "cc",
      name: "user#{unique_number}",
      num1: "4111111111111111",
      num2: "123",
      brand: "visa",
      active: true,
      lock: nil,
      account_id: account.id
    }

    payment_source =
      create_from_attrs(builder, AppCount.Accounts.PaymentSource, payment_source_attrs, extra)

    put_requirement(builder, :payment_source, payment_source)
  end

  def add_autopay(
        %Builder{req: %{account: account, payment_source: payment_source}} = builder,
        extra \\ []
      ) do
    autopay =
      %Autopay{
        active: true,
        account_id: account.id,
        payment_source_id: payment_source.id,
        payer_ip_address: "1.1.1.1.",
        last_run: nil,
        agreement_text: "I agree!",
        agreement_accepted_at: Clock.now()
      }
      |> Map.merge(Map.new(extra))

    {:ok, autopay} = create(builder, autopay, extra)

    put_requirement(builder, :autopay, autopay)
  end

  # --------------------------------------------------------
  # Private
  # --------------------------------------------------------
  def get(%Builder{} = builder, names) when is_list(names) do
    requirements =
      names
      |> Enum.map(fn name -> priv_get(builder, name) end)

    [builder] ++ requirements
  end

  defp priv_get(%Builder{req: req}, name) do
    Map.get(req, name, "#{name} Not Found")
  end

  def get_requirement(%Builder{req: req, mode: :create}, :property) do
    property = Map.fetch!(req, :property)
    AppCount.Properties.PropertyRepo.get_aggregate(property.id)
  end

  def get_requirement(%Builder{req: req}, name) do
    Map.get(req, name, "#{name} Not Found")
  end

  def put_requirement(%Builder{req: req} = builder, name, value) do
    req = Map.put(req, name, value)
    %{builder | req: req}
  end

  defp sequence(%Builder{sequence_num: sequence_num} = builder) do
    builder = %{builder | sequence_num: sequence_num + 1}
    {sequence_num, builder}
  end

  # defp create(%Builder{mode: :build}, schema, extra) do
  #   {:ok, schema |> merge(extra)}
  # end

  defp create(%Builder{mode: :create}, %module_name{} = schema, extra) do
    schema
    |> merge(extra)
    |> module_name.changeset(%{})
    |> Repo.insert()
  end

  # When we're working structs that have encrypted fields, we need to create
  # them slightly differently. In this case, we pass in an atom representing the
  # module name, e.g. AppCount.Properties.Processor, and a map with the various
  # attributes.
  def create_from_attrs(%Builder{}, module_name, attrs, extra) do
    params = merge(attrs, extra)

    {:ok, %{id: id}} =
      struct(module_name)
      |> module_name.changeset(params)
      |> Repo.insert()

    # Re-fetch so we get decrypted data
    Repo.get(module_name, id)
  end

  # defp put_association(target, association_name, association_struct, %Builder{mode: :create}) do
  #   association_name = "#{association_name}_id" |> String.to_atom()

  #   target
  #   |> Map.put(association_name, association_struct.id)
  # end

  # defp put_association(target, association_name, association_struct, %Builder{mode: :build}) do
  #   target
  #   |> Map.put(association_name, association_struct)
  # end

  defp merge(struct, extra_as_keyword_list) do
    Map.merge(struct, Map.new(extra_as_keyword_list))
  end
end
