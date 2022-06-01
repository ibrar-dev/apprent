defmodule AppCount.Controllers.API.IntegrationControllerTest do
  use AppCountWeb.ConnCase
  import Mock
  alias AppCount.Properties
  @moduletag :integration_controller

  setup do
    admin = AppCount.UserHelper.new_admin(%{roles: ["Super Admin"]})

    {:ok, admin: admin}
  end

  test_with_mock "index", %{conn: conn, admin: admin}, Properties, [:passthrough],
    list_processors: fn _ -> [%{name: "Authorize"}] end do
    result =
      conn
      |> admin_request(admin)
      |> get("https://administration.example.com/api/integrations")
      |> json_response(200)

    assert result == [%{"name" => "Authorize"}]
  end

  test_with_mock "show", %{conn: conn, admin: admin}, Properties, [:passthrough],
    get_bluemoon_property_ids: fn _ -> {:ok, %{data: "ok"}} end do
    result =
      conn
      |> admin_request(admin)
      |> get("https://administration.example.com/api/integrations/1?bluemoon_id=11111")
      |> json_response(200)

    assert result == %{"data" => "ok"}
  end

  test_with_mock "create Payscape success",
                 %{conn: conn, admin: admin},
                 Properties,
                 [:passthrough],
                 create_payscape_account_and_processor: fn _, _ -> {:ok, %{}} end do
    params = %{"create_account" => %{}, "processor" => %{}}

    result =
      conn
      |> admin_request(admin)
      |> post("https://administration.example.com/api/integrations", params)
      |> json_response(200)

    assert result == %{}
  end

  test_with_mock "create Payscape failure",
                 %{conn: conn, admin: admin},
                 Properties,
                 [:passthrough],
                 create_payscape_account_and_processor: fn _, _ ->
                   {:error, %{something: "went wrong"}}
                 end do
    params = %{"create_account" => %{}, "processor" => %{}}

    result =
      conn
      |> admin_request(admin)
      |> post("https://administration.example.com/api/integrations", params)
      |> json_response(422)

    assert result == %{"error" => %{"something" => "went wrong"}}
  end

  test_with_mock "create Processor success",
                 %{conn: conn, admin: admin},
                 Properties,
                 [:passthrough],
                 create_processor: fn _ -> {:ok, %{}} end do
    params = %{"processor" => %{}}

    result =
      conn
      |> admin_request(admin)
      |> post("https://administration.example.com/api/integrations", params)
      |> json_response(200)

    assert result == %{}
  end

  test_with_mock "create Processor failure",
                 %{conn: conn, admin: admin},
                 Properties,
                 [:passthrough],
                 create_processor: fn _ -> {:error, %{something: "went wrong"}} end do
    params = %{"processor" => %{}}

    result =
      conn
      |> admin_request(admin)
      |> post("https://administration.example.com/api/integrations", params)
      |> json_response(422)

    assert result == %{"error" => %{"something" => "went wrong"}}
  end

  test_with_mock "update Processor success",
                 %{conn: conn, admin: admin},
                 Properties,
                 [:passthrough],
                 update_processor: fn _, _ -> {:ok, %{}} end do
    params = %{"processor" => %{}}

    result =
      conn
      |> admin_request(admin)
      |> patch("https://administration.example.com/api/integrations/1", params)
      |> json_response(200)

    assert result == %{}
  end

  test_with_mock "update Processor failure",
                 %{conn: conn, admin: admin},
                 Properties,
                 [:passthrough],
                 update_processor: fn _, _ -> {:error, %{something: "went wrong"}} end do
    params = %{"processor" => %{}}

    result =
      conn
      |> admin_request(admin)
      |> patch("https://administration.example.com/api/integrations/1", params)
      |> json_response(422)

    assert result == %{"error" => %{"something" => "went wrong"}}
  end

  test_with_mock "delete Processor success",
                 %{conn: conn, admin: admin},
                 Properties,
                 [:passthrough],
                 delete_processor: fn _ -> {:ok, %{}} end do
    result =
      conn
      |> admin_request(admin)
      |> delete("https://administration.example.com/api/integrations/1")
      |> json_response(200)

    assert result == %{}
  end

  test_with_mock "delete Processor failure",
                 %{conn: conn, admin: admin},
                 Properties,
                 [:passthrough],
                 delete_processor: fn _ -> {:error, %{something: "went wrong"}} end do
    result =
      conn
      |> admin_request(admin)
      |> delete("https://administration.example.com/api/integrations/1")
      |> json_response(422)

    assert result == %{"error" => %{"something" => "went wrong"}}
  end
end
