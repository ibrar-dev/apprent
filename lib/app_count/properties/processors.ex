defmodule AppCount.Properties.Processors do
  @moduledoc """
  Query methods for looking up Processors for properties.

  Here is the list of processors so far:

  - Authorize - Credit card transactions
  - Payscape - ACH transactions
  - BlueMoon - Leasing
  - TenantSafe - tenant screening
  - Yardi - integrations w/ Yardi, which is another property management platform

  Processors are basically external services, and typically will have unique
  credentials per property.

  Some processors have username and password.

  Other processors have a number of API key values, which we describe (albeit
  incompletely) in the key_names map below.

  To find out which value goes with which key, you compare positions. It's
  tedious to do by hand, but also these values rarely change
  """

  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Properties.Processor
  alias AppCount.Core.ClientSchema

  @key_names %{
    "Authorize" => [:api_key, :transaction_key, :public_key],
    "Payscape" => [:cert, :term_id, :account_num],
    "BlueMoon" => [:serial, :user, :password, :property_id],
    "TenantSafe" => [:user_id, :password, :product_type],
    "Yardi" => [
      :username,
      :password,
      :platform,
      :server_name,
      :db,
      :url,
      :entity,
      :interface,
      :gl_account
    ]
  }

  def public_details(%AppCount.Properties.Property{} = property, :cc) do
    fetch(property.id, :cc)
    |> Authorize.PublicCredentials.credentials()
  end

  def public_details(property_id, :cc) do
    fetch(property_id, :cc)
    |> Authorize.PublicCredentials.credentials()
  end

  def public_details(_, _) do
    %{}
  end

  def fetch(%AppCount.Properties.Property{id: id} = property, :cc) do
    AppCount.Core.ClientSchema.new(property.__meta__.prefix, %{property_id: id})
    |> fetch(:cc)
  end

  def fetch(property_id, :cc) do
    fetch(property_id, %{type: "cc"})
  end

  def fetch(property_id, %{type: "cc"} = source) do
    env = Authorize.URL.environment()
    fetch(property_id, source, env)
  end

  def fetch(%AppCount.Core.ClientSchema{name: name, attrs: attrs}, source) do
    from(p in Processor, where: p.property_id == ^attrs.property_id and p.type == ^source.type)
    |> Repo.one(prefix: name)
  end

  # TODO: Legacy
  def fetch(property_id, source) do
    from(p in Processor, where: p.property_id == ^property_id and p.type == ^source.type)
    |> Repo.one()
  end

  # If we're using the Auth.net sandbox, e.g. in dev mode, use this fill-in
  def fetch(property_id, %{type: "cc"} = source, :sandbox) do
    Authorize.SandboxProcessor.processor(property_id, source)
  end

  # Pattern matching for ClientSchema. Keeping old one in case it's still being used
  # somewhere without schema injection.
  def fetch(
        %ClientSchema{name: client_schema, attrs: %{property_id: property_id}},
        %{type: "cc"} = source,
        :live
      ) do
    from(p in Processor, where: p.property_id == ^property_id and p.type == ^source.type)
    |> Repo.one(prefix: client_schema)
  end

  # Live credentials, stored in the DB
  def fetch(property_id, %{type: "cc"} = source, :live) do
    from(p in Processor, where: p.property_id == ^property_id and p.type == ^source.type)
    |> Repo.one()
  end

  def processor_credentials(
        %AppCount.Core.ClientSchema{name: client_schema, attrs: property_id},
        type
      ) do
    from(
      p in Processor,
      where: p.property_id == ^property_id and p.type == ^type,
      select: {p.name, p.keys}
    )
    |> Repo.one(prefix: client_schema)
    |> case do
      {name, keys} ->
        @key_names[name]
        |> Enum.zip(keys)
        |> Enum.into(%{})

      nil ->
        nil
    end
  end
end
