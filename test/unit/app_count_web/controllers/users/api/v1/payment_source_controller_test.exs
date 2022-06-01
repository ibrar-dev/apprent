defmodule AppCountWeb.Controllers.Users.API.V1.PaymentSourceControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Accounts
  import Mock

  setup do
    account =
      insert(:user_account)
      |> AppCount.UserHelper.new_account()

    insert(:lease, tenants: [account.tenant])
    ps = insert(:payment_source, account: account)
    {:ok, account: account, ps: ps}
  end

  @url "http://residents.example.com/api/v1/payment_sources"
  @tokenized_card_params %{
    "brand" => "visa",
    "token_description" => "COMMON.ACCEPT.INAPP.PAYMENT",
    "token_value" => "eyJ0b2tlbiI6Ijk1OTUzNjM5MTMwNjk2Mjk2MDQ2MDEiLCJ2IjoiMS4xIn0=",
    "type" => "cc",
    "exp" => "11/29",
    "card_name" => "Jack Jackson",
    "last_4" => "1111"
  }

  describe "index" do
    test "fetches", %{conn: conn, account: account, ps: ps} do
      source = Repo.get(Accounts.PaymentSource, ps.id)

      body =
        conn
        |> user_mobile_request(account)
        |> get(@url)
        |> json_response(200)

      card = hd(body)
      assert card["num1"] == "XXXX 1111"
      assert card["last_4"] == source.last_4
      assert card["brand"] == source.brand
      assert card["exp"] == source.exp
      assert card["active"]
      assert card["name"] == source.name
    end
  end

  describe "tokenization_credentials" do
    test "gets tokenization credentials", %{conn: conn, account: account} do
      new_conn =
        with_mock Authorize.FetchPublicKey,
                  [:passthrough],
                  fetch: fn _ -> %{public_key: "I am a public key"} end do
          conn
          |> user_mobile_request(account)
          |> get("http://residents.example.com/api/v1/tokenization_credentials")
        end

      assert json_response(new_conn, 200)
    end
  end

  describe "create" do
    @tag :slow
    test "tokenized cc payment source works", %{conn: conn, account: account} do
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
          |> user_mobile_request(account)
          |> post(@url, %{"cc_tokenized" => @tokenized_card_params})
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

    test "creates with bank account", %{conn: conn, account: account} do
      bank = insert(:bank)

      params = %{
        "routing_number" => bank.routing,
        "number" => "43211343",
        "account_name" => "Jack Jackson",
        "subtype" => "savings"
      }

      response =
        conn
        |> user_mobile_request(account)
        |> post(@url, ba: params)
        |> json_response(200)

      assert response["id"]
      ps = Repo.get(Accounts.PaymentSource, response["id"])
      assert ps.num2 == bank.routing
      assert ps.brand == bank.name
      assert ps.name == "Jack Jackson"
      assert ps.type == "ba"
      assert ps.last_4 == "1343"
      assert ps.subtype == "savings"
    end
  end
end
