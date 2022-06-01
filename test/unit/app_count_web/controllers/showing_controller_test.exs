defmodule AppCountWeb.ShowingControllerTest do
  use AppCountWeb.ConnCase

  test "index page loads", %{conn: conn} do
    property = insert(:property)

    response =
      conn
      |> get("http://application.example.com/showings/#{property.code}")
      |> html_response(200)

    assert response =~ "AppRent"
  end
end
