defmodule AppCountWeb.ApplicationFormController do
  use AppCountWeb, :public_controller
  alias AppCount.RentApply
  alias AppCount.Properties

  def index(conn, %{"property_code" => code}) do
    with %{__meta__: meta} <- AppCount.Public.PropertyRepo.client_property_from_code(code),
         %Properties.Property{} = prop <-
           Properties.get_property_with_payment_keys([code: code], meta.prefix) do
      conn
      |> put_layout(false)
      |> render("index.html", property: prop, client_schema: meta.prefix, mode: "")
    else
      _ -> send_resp(conn, 404, "No such property")
    end
  end

  def index(conn, %{"crypt" => crypt}) do
    crypt
    |> AppCount.Crypto.LocalCryptoServer.decrypt()
    |> case do
      {:ok, id} ->
        application = RentApply.get_application(id)
        unit = Properties.get_unit(application.approval_params.unit_id)

        conn
        |> put_layout(false)
        |> render("payment.html", application: application, unit: unit)

      {:error, _msg} ->
        conn
        |> put_status(:not_found)
        |> put_layout(false)
        |> render("not_found.html")
    end
  end

  def edit(conn, %{"id" => id}) do
    # This endpoint is actually an admin-only one, we should probably move this out
    # so it's clearer and so the appropriate plugs can apply
    client_schema = AppCount.Core.ClientSchema.new(conn.assigns.user.client_schema, %{id: id})
    application = RentApply.get_application_data(client_schema)

    property =
      Properties.get_property_with_payment_keys(
        application.property.id,
        conn.assigns.user.client_schema
      )

    application_json =
      Map.delete(application, :payments)
      |> Map.delete(:property)
      |> Map.delete(:payments)
      |> Jason.encode!()

    property_data =
      Properties.public_property_data(application.property.code)
      |> Jason.encode!()

    conn
    |> put_layout(false)
    |> render(
      "index.html",
      property: property,
      property_data: property_data,
      mode: "edit",
      application: application_json
    )
  end
end
