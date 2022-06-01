defmodule AppCountWeb.Controllers.Users.PaymentSourceControllerTest do
  import Mock
  use AppCountWeb.ConnCase
  alias AppCount.Accounts
  alias AppCount.Support.HTTPClient
  @moduletag :payment_source_controller

  @url "http://residents.example.com/payment_sources"

  setup do
    account =
      insert(:user_account)
      |> AppCount.UserHelper.new_account()

    insert(:tenancy, tenant: account.tenant)
    ps = insert(:payment_source, account: account)
    response = File.read!(Path.expand("../../../resources/authorize/token_response.xml", __DIR__))
    HTTPClient.initialize([response, response])
    on_exit(fn -> HTTPClient.stop() end)
    {:ok, account: account, ps: ps}
  end

  describe "#index" do
    @tag :slow
    test "user payment sources page loads", %{conn: conn, account: account} do
      response =
        conn
        |> user_request(account)
        |> get(@url)
        |> html_response(200)

      assert response =~ "Payment Sources"
      assert response =~ "XXXX XXXX XXXX 1111"
    end
  end

  describe "#create" do
    @tag :slow
    test "tokenized cc payment source works", %{conn: conn, account: account} do
      params = %{
        "brand" => "visa",
        "token_description" => "COMMON.ACCEPT.INAPP.PAYMENT",
        "token_value" => "eyJ0b2tlbiI6Ijk1OTUzNjM5MTMwNjk2Mjk2MDQ2MDEiLCJ2IjoiMS4xIn0=",
        "type" => "cc",
        "exp" => "11/29",
        "card_name" => "Jack Jackson",
        "last_4" => "1111"
      }

      new_conn =
        with_mock Authorize.CreateCustomer,
                  [:passthrough],
                  create_profile: fn _, _ ->
                    {:ok,
                     %{
                       authorize_payment_profile_id: "67890",
                       authorize_profile_id: "12345",
                       original_network_transaction_id: "12345",
                       original_auth_amount_in_cents: 1
                     }}
                  end do
          conn
          |> user_request(account)
          |> post(@url, cc: params)
        end

      assert %{"id" => id} = json_response(new_conn, 200)

      ps = Repo.get(Accounts.PaymentSource, id)

      assert ps.name == "Jack Jackson"
      assert ps.is_tokenized
      assert ps.exp == "11/29"
      assert ps.brand == "visa"
      assert ps.type == "cc"
      assert ps.last_4 == "1111"
      assert ps.num1 == "12345"
      assert ps.num2 == "67890"
    end

    @tag :slow
    test "user create payment source works(ba)", %{conn: conn, account: account} do
      bank = insert(:bank)

      params = %{
        "routing_number" => bank.routing,
        "account_number" => "43211343",
        "account_name" => "Jack Jackson",
        "subtype" => "checking"
      }

      response =
        conn
        |> user_request(account)
        |> post(@url, ba: params)
        |> json_response(200)

      assert response["id"]
      ps = Repo.get(Accounts.PaymentSource, response["id"])
      assert ps.num2 == bank.routing
      assert ps.num1 == "43211343"
      assert ps.brand == bank.name
      assert ps.name == "Jack Jackson"
      assert ps.type == "ba"
      assert ps.last_4 == "1343"
      assert ps.subtype == "checking"
    end

    @tag :slow
    test "user create payment source error handling(ba)", %{conn: conn, account: account} do
      bank = insert(:bank)
      params = %{"routing_number" => bank.routing}

      response =
        conn
        |> user_request(account)
        |> post(@url, ba: params)
        |> json_response(422)

      assert response
    end
  end

  describe "delete" do
    @tag :slow
    test "user delete payment source works", %{conn: conn, account: account, ps: ps} do
      conn
      |> user_request(account)
      |> delete(@url <> "/#{ps.id}")
      |> html_response(302)
      |> assert

      refute Repo.get(Accounts.PaymentSource, ps.id).active
    end
  end
end
