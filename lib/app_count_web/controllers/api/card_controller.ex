defmodule AppCountWeb.API.CardController do
  use AppCountWeb, :controller
  alias AppCount.Core.ClientSchema

  authorize(["Tech", "Admin"],
    index: ["Admin", "Agent", "Tech", "Accountant"],
    update: ["Admin", "Tech"],
    delete: [
      "Super Admin",
      "Admin",
      "Tech",
      "Regional"
    ]
  )

  def index(conn, %{"property_ids" => property_ids, "hidden_cards" => _hidden_cards}) do
    property_ids_as_string = String.split(property_ids, ",")

    result =
      maintenance(conn).list_cards(
        ClientSchema.new(conn.assigns.admin),
        property_ids_as_string,
        :hidden
      )

    json(conn, result)
  end

  def index(conn, %{"property_ids" => property_ids}) do
    property_ids_as_string = String.split(property_ids, ",")

    json(
      conn,
      maintenance(conn).list_cards(
        ClientSchema.new(conn.assigns.admin),
        property_ids_as_string,
        :active
      )
    )
  end

  def create(conn, %{"card" => params}) do
    maintenance(conn).create_card(Map.merge(params, %{"admin" => conn.assigns.admin.name}))
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "card" => params}) do
    case params["completion_status"] do
      "completed" ->
        new_params =
          params
          |> Map.merge(%{
            "completion" => %{
              name: conn.assigns.admin.name,
              date: AppCount.current_time()
            }
          })

        maintenance(conn).update_card(id, new_params)

      "incomplete" ->
        maintenance(conn).update_card(id, Map.put(params, "completion", nil))

      _ ->
        maintenance(conn).update_card(id, params)
    end

    json(conn, %{})
  end

  def show(conn, %{"id" => "last_domain_event", "card_ids" => card_ids}) do
    case maintenance(conn).list_last_domain_event(String.split(card_ids, ",")) do
      {:ok, %{subject_id: _id} = event} ->
        json(conn, event)

      _ ->
        put_status(conn, 200)
        |> json(%{})
    end
  end
end
