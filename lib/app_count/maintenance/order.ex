defmodule AppCount.Maintenance.Order do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias AppCount.Maintenance.Order

  schema "maintenance__orders" do
    field(:allow_sms, :boolean, default: true)
    field(:cancellation, :map)
    field(:created_by, :string, default: nil)
    field(:entry_allowed, :boolean, default: false)
    field(:has_pet, :boolean, default: false)
    field(:no_access, {:array, :map}, default: [])
    field(:priority, :integer, default: 0)
    field(:require_image, :boolean, default: false)

    # status can be:
    # ["completed", "assigned", "unassigned", "cancelled",  and  nil ]
    field(:status, :string)
    field(:ticket, :string, default: "UNKNOWN")
    field(:uuid, Ecto.UUID)

    belongs_to(:card_item, AppCount.Maintenance.CardItem)
    belongs_to(:category, AppCount.Maintenance.Category)
    belongs_to(:property, AppCount.Properties.Property)
    belongs_to(:tenant, AppCount.Tenants.Tenant)
    belongs_to(:unit, AppCount.Properties.Unit)

    has_many(:assignments, AppCount.Maintenance.Assignment)
    has_many(:notes, AppCount.Maintenance.Note)
    has_many(:parts, AppCount.Maintenance.Part)

    timestamps()
  end

  @doc false
  def changeset(%Order{} = order, attrs) do
    order
    |> cast(
      attrs,
      [
        :category_id,
        :tenant_id,
        :property_id,
        :unit_id,
        :has_pet,
        :entry_allowed,
        :priority,
        :uuid,
        :inserted_at,
        :ticket,
        :cancellation,
        :card_item_id,
        :no_access,
        :created_by,
        :status,
        :require_image,
        :allow_sms
      ]
    )
    |> validate_required([
      :category_id,
      :property_id,
      :has_pet,
      :entry_allowed,
      :priority,
      :ticket
    ])
    |> unique_constraint(:uuid, name: :maintenance__orders_uuid_index)
    |> unique_constraint(:card_item_id, name: :maintenance__orders_card_item_id_index)
  end

  def new(
        category_id: category_id,
        property_id: property_id,
        has_pet: has_pet,
        entry_allowed: entry_allowed,
        priority: priority,
        ticket: ticket
      ) do
    %__MODULE__{
      category_id: category_id,
      property_id: property_id,
      has_pet: has_pet,
      entry_allowed: entry_allowed,
      priority: priority,
      ticket: ticket,
      uuid: Ecto.UUID.generate()
    }
  end

  @spec current_assignment(%__MODULE__{}) :: %AppCount.Maintenance.Assignment{} | nil
  def current_assignment(%{assignments: []}), do: nil

  def current_assignment(%{assignments: assignments}) do
    assignments
    |> Enum.sort_by(&Timex.to_unix(&1.inserted_at))
    |> List.last()
  end

  def add_status_to_all(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: _
      }) do
    # TODO:SCHEMA  389 does not look good
    admin = AppCount.Repo.get(AppCount.Admins.Admin, 389, prefix: client_schema)

    from(
      o in Order,
      where: not is_nil(o.status),
      select: o.id,
      order_by: [desc: :inserted_at]
    )
    |> AppCount.Repo.all(prefix: client_schema)
    |> Enum.each(&get_and_update_status(&1, admin))
  end

  def url(order_id) do
    domain = AppCount.namespaced_url("residents")
    ~s[#{domain}/order/#{order_id}]
  end

  defp get_and_update_status(id, %AppCount.Core.ClientSchema{
         name: client_schema,
         attrs: admin
       }) do
    case AppCount.Maintenance.Utils.Queries.ShowOrder.show_order(
           %AppCount.Core.ClientSchema{
             name: client_schema,
             attrs: admin
           },
           id
         ) do
      %{status: status} ->
        AppCount.Repo.get(Order, id, prefix: client_schema)
        |> Order.changeset(%{status: status})
        |> AppCount.Repo.update(prefix: client_schema)

      _ ->
        nil
    end
  end
end
