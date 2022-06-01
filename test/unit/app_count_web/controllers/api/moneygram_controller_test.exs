defmodule AppCountWeb.APIController.API.MoneyGramControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Repo
  @moduletag :moneygram_controller

  @validation_request File.read!(
                        Path.expand(
                          "../../../resources/moneygram/validation_request.xml",
                          __DIR__
                        )
                      )
  @validation_response File.read!(
                         Path.expand(
                           "../../../resources/moneygram/validation_response.xml",
                           __DIR__
                         )
                       )
  @failure_response File.read!(
                      Path.expand("../../../resources/moneygram/failure_response.xml", __DIR__)
                    )
  @load_request File.read!(Path.expand("../../../resources/moneygram/load_request.xml", __DIR__))
  @load_response File.read!(
                   Path.expand("../../../resources/moneygram/load_response.xml", __DIR__)
                 )
  @load_failure File.read!(Path.expand("../../../resources/moneygram/load_failure.xml", __DIR__))

  test "valid validation request", %{conn: conn} do
    insert(:tenant, id: 123_456_789)

    resp =
      conn
      |> put_req_header("content-type", "text/xml")
      |> post("http://administration.example.com/money_gram", @validation_request)

    assert response(resp, 200) == String.replace(@validation_response, ~r"(\s\s+)|\n", "")
  end

  test "invalid validation request", %{conn: conn} do
    insert(:tenant, id: 123_456_790)

    resp =
      conn
      |> put_req_header("content-type", "text/xml")
      |> post("http://administration.example.com/money_gram", @validation_request)

    t_id =
      "123456789-#{
        AppCount.current_time()
        |> Timex.to_unix()
      }"

    expected_response =
      @failure_response
      |> String.replace(
        ~r"\<partnerTransactionID\>957864123\</partnerTransactionID\>",
        "<partnerTransactionID>1010#{t_id}</partnerTransactionID>"
      )
      |> String.replace(~r"(\s\s+)|\n", "")

    assert response(resp, 200) == expected_response
  end

  test "valid load request", %{conn: conn} do
    tenant = insert(:tenant, id: 123_456_789)
    tenancy = insert(:tenancy, tenant: tenant)

    resp =
      conn
      |> put_req_header("content-type", "text/xml")
      |> post("http://administration.example.com/money_gram", @load_request)

    payment =
      Repo.get_by(
        AppCount.Ledgers.Payment,
        tenant_id: tenant.id,
        property_id: tenancy.unit.property_id,
        amount: 100
      )

    expected_response =
      @load_response
      |> String.replace(
        ~r"\<partnerTransactionID\>957864123\</partnerTransactionID\>",
        "<partnerTransactionID>#{payment.id}</partnerTransactionID>"
      )
      |> String.replace(~r"(\s\s+)|\n", "")

    assert response(resp, 200) == expected_response
  end

  test "invalid load request", %{conn: conn} do
    tenancy = insert(:tenancy, tenant: insert(:tenant, id: 123_456_790))

    resp =
      conn
      |> put_req_header("content-type", "text/xml")
      |> post("http://administration.example.com/money_gram", @load_request)

    refute Repo.get_by(
             AppCount.Ledgers.Payment,
             property_id: tenancy.unit.property_id,
             amount: 100
           )

    t_id =
      AppCount.current_time()
      |> Timex.to_unix()

    expected_response =
      @load_failure
      |> String.replace(
        ~r"\<partnerTransactionID\>957864123\</partnerTransactionID\>",
        "<partnerTransactionID>123456789-#{t_id}</partnerTransactionID>"
      )
      |> String.replace(~r"(\s\s+)|\n", "")

    assert response(resp, 200) == String.replace(expected_response, ~r"(\s\s+)|\n", "")
  end
end
