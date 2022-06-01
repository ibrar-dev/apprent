defmodule AppCountWeb.ApplicationFormControllerTest do
  use AppCountWeb.ConnCase
  @moduletag :application_form_controller

  setup do
    {:ok, []}
  end

  test "admin payment page works", %{conn: conn} do
    application =
      insert(
        :rent_application,
        approval_params: %{
          unit_id: insert(:unit).id
        }
      )

    {:ok, crypt} = AppCount.Crypto.LocalCryptoServer.encrypt("#{application.id}")

    encoded_crypt =
      crypt
      |> URI.encode_www_form()

    result =
      conn
      |> get("http://application.example.com/payment/#{encoded_crypt}")
      |> html_response(200)

    assert result =~ application.property.name
  end

  describe "index/2" do
    test "404s with a missing property", %{conn: conn} do
      conn =
        conn
        |> get("http://application.example.com/not-a-real-property")

      assert response(conn, 404)
    end
  end
end
