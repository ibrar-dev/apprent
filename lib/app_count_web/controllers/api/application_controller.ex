defmodule AppCountWeb.API.ApplicationController do
  use AppCountWeb, :controller
  alias AppCount.RentApply
  alias AppCountWeb.LetterPreviewer
  alias AppCount.RentApply.Utils.RentApplications
  alias AppCount.Core.ClientSchema

  authorize(["Admin", "Agent"])

  def create(conn, %{"memos" => _} = params) do
    RentApply.create_memo(params, conn.assigns.admin)
    json(conn, %{})
  end

  def create(conn, %{"create_document" => _, "params" => params}) do
    RentApply.create_document(params)
    json(conn, %{})
  end

  def create(conn, %{
        "rental_verification_form_preview" => _,
        "property_id" => property_id,
        "html" => html
      }) do
    params = %{"property_id" => property_id}

    case LetterPreviewer.generate_preview(
           html,
           params
         ) do
      {:ok, binary} ->
        json(conn, %{pdf: Base.encode64(binary)})

      _ ->
        json(conn, %{error: "ERROR GENERATING PREVIEW"})
    end
  end

  def create(conn, %{
        "rental_verification_form" => _,
        "property_id" => property_id,
        "person_id" => person_id
      }) do
    params = %{"property_id" => property_id, "person_id" => person_id}

    case RentApplications.generate_rent_verify_form(params, &LetterPreviewer.generate_preview/2) do
      {:ok, binary} -> json(conn, %{pdf: Base.encode64(binary)})
      {:error, error} -> handle_error({:error, error}, conn)
    end
  end

  def index(conn, %{
        "property_id" => property_id,
        "start_date" => start_date,
        "end_date" => end_date
      }) do
    applications =
      RentApply.list_applications(
        ClientSchema.new(conn.assigns.admin),
        property_id,
        start_date,
        end_date
      )

    credentials_list = RentApply.get_integration_credentials(conn.assigns.admin)
    json(conn, %{applications: applications, credentials_list: credentials_list})
  end

  def index(conn, %{"find_applicants" => _, "property_id" => property_id}) do
    json(conn, RentApply.get_property_applications(property_id))
  end

  def index(conn, %{"payment_applicants" => _, "property_id" => property_id}) do
    json(conn, RentApply.get_applicants_for_payments(property_id))
  end

  def index(conn, %{"property_id" => property_id}) do
    applications =
      RentApply.list_applications(ClientSchema.new(conn.assigns.admin), property_id: property_id)

    credentials_list = RentApply.get_integration_credentials(conn.assigns.admin)
    json(conn, %{applications: applications, credentials_list: credentials_list})
  end

  def show(conn, %{"id" => id, "payment_url_send" => _}) do
    RentApply.send_payment_url(id)
    json(conn, %{})
  end

  def show(conn, %{"id" => id, "payment_url" => _}) do
    {:ok, crypt} = AppCount.Crypto.LocalCryptoServer.encrypt("#{id}")

    encoded_crypt =
      crypt
      |> URI.encode_www_form()

    url = "#{AppCount.namespaced_url("application")}/payment/#{encoded_crypt}"
    json(conn, %{url: url})
  end

  def show(conn, %{"id" => id, "ledger" => _}) do
    json(conn, RentApply.get_application_ledger(id))
  end

  def show(conn, %{"id" => id}) do
    client_schema = AppCount.Core.ClientSchema.new(conn.assigns.user.client_schema, %{id: id})
    json(conn, RentApply.get_application_data(client_schema))
  end

  def update(conn, %{"id" => id, "application" => params, "full" => _}) do
    RentApply.full_update_application(id, params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "application" => params}) do
    RentApply.update_application(id, params)
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "approve" => params}) do
    RentApply.get_application(id)
    |> RentApply.preapprove(params)
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "bypass" => params}) do
    RentApply.get_application(id)
    |> RentApply.bypass_approve(params)
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "declined_reason" => reason}) do
    params = %{
      "declined_reason" => reason,
      "declined_by" => conn.assigns.admin.name,
      "declined_on" => AppCount.current_time(),
      "status" => "declined",
      "approval_params" => %{}
    }

    RentApply.update_application(id, params)
    json(conn, %{})
  end
end
