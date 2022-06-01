defmodule AppCount.Accounting.Utils.Closings do
  alias AppCount.Repo
  alias AppCount.Admins
  alias AppCount.Accounting.Closing
  import Ecto.Query
  alias AppCount.Core.ClientSchema

  def list_closings(%ClientSchema{
        name: client_schema,
        attrs: admin
      }) do
    from(
      c in Closing,
      join: a in assoc(c, :admin),
      where:
        c.property_id in ^Admins.property_ids_for(%ClientSchema{
          name: client_schema,
          attrs: admin
        }),
      select: map(c, [:id, :closed_on, :property_id, :type]),
      select_merge: %{
        month: fragment("to_char(?, 'MM/YYYY')", c.month),
        admin: a.name
      },
      order_by: [
        desc: c.month
      ]
    )
    |> Repo.all(prefix: client_schema)
  end

  def create_closing(
        %ClientSchema{
          name: client_schema,
          attrs: admin
        },
        params
      ) do
    if Enum.member?(
         Admins.property_ids_for(ClientSchema.new(client_schema, admin)),
         params["property_id"]
       ) do
      %Closing{}
      |> Closing.changeset(Map.put(params, "admin_id", admin.id))
      |> Repo.insert(prefix: client_schema)
    end
  end

  def update_closing(
        %ClientSchema{
          name: client_schema,
          attrs: admin
        },
        id,
        params
      ) do
    closing = Repo.get(Closing, id, prefix: client_schema)

    if Enum.member?(
         Admins.property_ids_for(%ClientSchema{
           name: client_schema,
           attrs: admin
         }),
         closing.property_id
       ) do
      closing
      |> Closing.changeset(params)
      |> Repo.update(prefix: client_schema)
    end
  end

  def delete_closing(
        %ClientSchema{
          name: client_schema,
          attrs: admin
        },
        id
      ) do
    closing = Repo.get(Closing, id, prefix: client_schema)

    if Enum.member?(
         Admins.property_ids_for(ClientSchema.new(client_schema, admin)),
         closing.property_id
       ) do
      Repo.delete(closing, prefix: client_schema)
    end
  end

  def get_post_date(property_id, inserted_at, starting_date, type)
      when is_binary(starting_date) do
    case Timex.parse(starting_date, "{YYYY}-{M}-{D}") do
      {:ok, time} ->
        get_post_date(property_id, inserted_at, time, type)

      _ ->
        get_post_date(
          property_id,
          inserted_at,
          Timex.parse!(starting_date, "{ISO:Extended}"),
          type
        )
    end

    #    Timex.parse!(starting_date, "{YYYY}-{M}-{D}")
    #    get_post_date(property_id, inserted_at, Timex.parse!(starting_date, "{YYYY}-{M}-{D}"), type)
  end

  def get_post_date(property_id, inserted_at, starting_date, type) do
    target_month =
      Timex.beginning_of_month(starting_date)
      |> Timex.to_date()

    from(
      c in Closing,
      where: c.property_id == ^property_id and c.month == ^target_month and c.type == ^type,
      select: c.closed_on
    )
    |> Repo.one()
    |> case do
      nil ->
        target_month

      date_closed ->
        if Timex.compare(inserted_at, date_closed, :seconds) == 1 do
          new_date =
            starting_date
            |> Timex.shift(months: 1)
            |> Timex.beginning_of_month()

          get_post_date(property_id, inserted_at, new_date, type)
        else
          target_month
        end
    end
  end
end
