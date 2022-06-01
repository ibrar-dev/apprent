defmodule AppCountWeb.API.SavedFormController do
  use AppCountWeb, :public_controller

  alias AppCount.RentApply.Forms
  alias AppCount.RentApply.Forms.SavedForm

  action_fallback(AppCountWeb.FallbackController)

  def create(conn, %{
        "property_id" => property_id,
        "saved_form" => saved_form_params,
        "form_data" => form_data_params
      }) do
    with {:ok, %SavedForm{} = saved_form} <-
           Forms.create_saved_form(property_id, saved_form_params, form_data_params) do
      conn
      |> put_status(:created)
      |> render("show.json", saved_form: saved_form)
    end
  end

  def show(conn, %{"property_id" => property_id, "email" => email, "pin" => pin}) do
    case Forms.get_decrypted_form(property_id, email, pin) do
      {:ok, saved_form} ->
        render(conn, "show.json", saved_form: saved_form)

      {:error, :bad_auth} ->
        put_status(conn, 403)
        |> json(%{error: "Invalid email or PIN"})
    end
  end
end
