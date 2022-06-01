defmodule AppCountWeb.Controllers.Users.StaticPageControllerTest do
  use AppCountWeb.ConnCase
  @moduletag :static_controller

  test "static pages work", %{conn: conn} do
    [:privacy, :about, :contact, :accept]
    |> Enum.each(fn page ->
      conn
      |> get("http://residents.example.com/#{page}")
      |> html_response(200)
      |> assert
    end)
  end

  # No longer using zendesk and even tho these tests passed it didnt work.
  test "ticket submission works", %{conn: _conn} do
    # Will fill out after confirming it works on prod
  end

  # No longer using zendesk and even tho these tests passed it didnt work.
  test "ticket submission works when logged in", %{conn: _conn} do
    # Will fill out after confirming it works on prod
  end

  test "accept works and has accept js url", %{conn: conn} do
    response =
      conn
      |> get("http://residents.example.com/accept")
      |> html_response(200)

    assert response =~ "authorize.net/v1/Accept.js"
  end
end
