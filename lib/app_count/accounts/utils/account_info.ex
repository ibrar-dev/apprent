defmodule AppCount.Accounts.Utils.AccountInfo do
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Maintenance.Assignment
  alias AppCount.Maintenance.Note
  alias AppCount.Maintenance.Order
  alias AppCount.Maintenance.Utils.OrderPublisher
  alias AppCount.Properties.Document
  alias AppCount.Repo
  alias AppCount.Tenants.TenancyRepo
  alias AppCount.Ledgers.CustomerLedgerRepo
  alias AppCount.Core.ClientSchema

  def user_balance(%AppCount.Core.ClientSchema{name: client_schema, attrs: tenant_id}) do
    # TODO we will need to reason about tenants with more than one current tenancy
    tenancy = TenancyRepo.active_tenancy_for_tenant(tenant_id)

    # IF tenancy is nil set balance to 0, rather than crash.
    case tenancy do
      nil ->
        %{balance: Decimal.new(0), date: AppCount.current_date()}
        |> parse_ledger()

      _ ->
        if TenancyRepo.tenancy_property_settings(tenancy.id).sync_ledgers do
          %{
            date: AppCount.current_date(),
            balance: tenancy.external_balance
          }
          |> parse_ledger()
        else
          balance =
            CustomerLedgerRepo.ledger_balance(
              ClientSchema.new(client_schema, tenancy.customer_ledger_id)
            )

          %{date: AppCount.current_date(), balance: balance}
          |> parse_ledger()
        end
    end
  end

  @spec user_balance_total(integer | String.t()) :: %Decimal{}
  def user_balance_total(tenant_id) do
    user_balance(ClientSchema.new("dasmen", tenant_id))
    |> Enum.reduce(Decimal.new(0), &Decimal.add(&2, &1.balance))
  end

  @spec get_documents(integer | String.t()) :: list
  def get_documents(user_id) do
    from(
      d in Document,
      join: u in assoc(d, :document_url),
      select: map(d, [:id, :name, :type, :inserted_at]),
      select_merge: %{
        url: u.url
      },
      where: d.tenant_id == ^user_id and d.visible == true
    )
    |> Repo.all()
  end

  def get_orders(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: user_id
      }) do
    from(
      o in Order,
      left_join: n in assoc(o, :notes),
      left_join: a in assoc(o, :assignments),
      join: c in assoc(o, :category),
      join: sc in assoc(c, :parent),
      where: o.tenant_id == ^user_id,
      select:
        map(o, [:id, :has_pet, :entry_allowed, :ticket, :cancellation, :status, :inserted_at]),
      select_merge: %{
        category: fragment("? || ' -- ' || ?", sc.name, c.name)
      },
      select_merge: %{
        notes: jsonize(n, [:id, :text, :image, :inserted_at])
      },
      select_merge: %{
        assignments: jsonize(a, [:id, :status, :rating], a.inserted_at, "DESC")
      },
      order_by: [
        desc: o.inserted_at
      ],
      group_by: [o.id, c.id, sc.id]
    )
    |> Repo.all(prefix: client_schema)
  end

  def get_order(user_id, id) do
    from(
      o in Order,
      left_join: n in assoc(o, :notes),
      where: o.id == ^id and o.tenant_id == ^user_id,
      select: struct(o, [:id, :category_id, :ticket, :has_pet, :entry_allowed]),
      select_merge: %{
        notes: jsonize(n, [:id, :image, :text])
      },
      group_by: o.id
    )
    |> Repo.one()
  end

  def get_assignment(user_id, id) do
    from(
      asgn in Assignment,
      join: ord in assoc(asgn, :order),
      where: asgn.id == ^id and ord.tenant_id == ^user_id,
      select: struct(asgn, [:id, :rating, :tenant_comment, :order_id])
    )
    |> Repo.one()
  end

  # called from phone or web-portal
  def create_order(user_id, params) do
    # TODO:SCHEMA
    client_schema = "dasmen"
    unit_info = AppCount.Accounts.unit_info(user_id)

    %Order{}
    |> Order.changeset(
      Map.merge(
        params,
        %{
          "tenant_id" => user_id,
          "property_id" => unit_info.property_id,
          "unit_id" => unit_info.unit_id,
          "uuid" => UUID.uuid4(),
          "status" => "unassigned"
        }
      )
    )
    |> Repo.insert()
    |> case do
      {:ok, order} ->
        update_order(user_id, order.id, %{"ticket" => ticket(order.id)})
        create_note(user_id, order.id, params["notes"], params["image"])

        AppCount.Rewards.create_accomplishment(
          ClientSchema.new(client_schema, %{
            tenant_id: user_id,
            type: "Work Order Created"
          })
        )

        OrderPublisher.publish_order_created_event(order)
        {:ok, order}

      e ->
        e
    end
  end

  defp create_note(_, _, nil, nil), do: nil

  defp create_note(user_id, order_id, notes, nil) do
    %Note{}
    |> Note.changeset(%{order_id: order_id, text: notes, tenant_id: user_id})
    |> Repo.insert()
  end

  defp create_note(user_id, order_id, notes, image) do
    process_note_and_image(user_id, order_id, notes, image)
  end

  defp process_note_and_image(_user_id, _order_id, _notes, nil) do
    {:ok, nil}
  end

  defp process_note_and_image(user_id, order_id, notes, image) when is_binary(image) do
    file_binary = Base.decode64!(image)

    filename =
      UUID.uuid4()
      |> String.upcase()

    %Note{}
    |> Note.changeset(%{order_id: order_id, text: notes, image: filename, tenant_id: user_id})
    |> Repo.insert()
    |> put_image(filename, file_binary)
  end

  defp process_note_and_image(user_id, order_id, notes, %Plug.Upload{} = image_upload) do
    filename =
      UUID.uuid4()
      |> String.upcase()

    {:ok, file_binary} =
      image_upload.path
      |> File.read()

    %Note{}
    |> Note.changeset(%{order_id: order_id, text: notes, image: filename, tenant_id: user_id})
    |> Repo.insert()
    |> put_image(filename, file_binary)
  end

  # Yes, we can post!
  defp put_image({:ok, note}, filename, file_binary) do
    AppCount.Maintenance.Utils.Notes.put_image(note.id, filename, file_binary)
  end

  # Probably we got {:error, some-error}
  defp put_image(error, _filename, _file_binary) do
    error
  end

  def update_order(user_id, id, params) do
    from(o in Order, where: o.tenant_id == ^user_id and o.id == ^id)
    |> Repo.one()
    |> Order.changeset(params)
    |> Repo.update()
    |> case do
      {:ok, order} ->
        create_note(user_id, order.id, params["notes"], params["image"])
        {:ok, order}

      e ->
        e
    end
  end

  def delete_order(user_id, id) do
    from(o in Order, where: o.tenant_id == ^user_id and o.id == ^id)
    |> Repo.one()
    |> Repo.delete()
  end

  defp ticket(id) do
    :crypto.hash(:md5, "#{id}")
    |> Base.encode16()
    |> String.slice(22, 10)
  end

  defp parse_ledger(entry) when is_nil(entry), do: []
  defp parse_ledger(%{balance: bal, date: date}) when is_nil(bal) or is_nil(date), do: []

  defp parse_ledger(%{balance: bal, date: date}) do
    date = Timex.format!(date, "{M}/{YYYY}")

    cond do
      Decimal.cmp(bal, 0) == :eq -> []
      true -> [%{balance: bal, date: date}]
    end
  end

  defp parse_ledger(_), do: []
end
