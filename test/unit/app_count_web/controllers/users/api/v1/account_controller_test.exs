defmodule AppCountWeb.Users.Api.V1.AccountControllerTest do
  use AppCountWeb.ConnCase
  import AppCount.LeasingHelper

  setup(~M[conn]) do
    account = insert(:user_account)
    insert_lease(%{tenants: [account.tenant]})

    account =
      account
      |> AppCount.UserHelper.new_account()

    conn =
      conn
      |> user_mobile_request(account)

    ~M[conn, account]
  end

  describe "index" do
    test "returns user data", ~M[conn, account] do
      result =
        conn
        |> get("http://residents.example.com/api/v1/profile")
        |> json_response(200)

      assert result["user"]["account_id"] == account.id
    end
  end

  describe "update/2" do
    test "invalid update w/ tenant data", ~M[conn] do
      invalid_params = %{
        "account" => %{
          email: 123
        }
      }

      # When
      new_conn =
        conn
        |> patch("http://residents.example.com/api/v1/profile", invalid_params)

      assert body = json_response(new_conn, 400)

      assert body == %{
               "error" => %{
                 "email" => ["is invalid"]
               }
             }
    end

    test "valid update w/ tenant data", ~M[conn, account] do
      valid_params = %{
        "account" => %{
          email: "all_your_base@are_belong_to_us.com"
        }
      }

      # When
      new_conn =
        conn
        |> patch("http://residents.example.com/api/v1/profile", valid_params)

      assert body = json_response(new_conn, 200)

      assert body == %{
               "user" => %{
                 "first_name" => account.tenant.first_name,
                 "last_name" => account.tenant.last_name
               }
             }
    end
  end
end
