defmodule AppCountWeb.Users.API.V1.PaymentControllerTest do
  use AppCount.Case
  use AppCountWeb.ConnCase

  defmodule AccountsParrot do
    use TestParrot
    parrot(:accounts, :account_lock_exists?, false)
    parrot(:accounts, :list_payments, [])
    parrot(:accounts, :user_balance, [])
  end

  describe "index" do
    setup(~M[conn]) do
      account =
        insert(:user_account)
        |> AppCount.UserHelper.new_account()

      conn =
        conn
        |> user_mobile_request(account)
        |> assign(:accounts_boundary, AccountsParrot)

      ~M[conn, account]
    end

    test "returns proper payments-blocked status when cash-only", ~M[conn] do
      AccountsParrot.say_account_lock_exists?(true)

      conn = get(conn, Routes.user_api_v1_payment_path(conn, :index))

      assert json_response(conn, 200) == %{
               "block_online_payments" => true,
               "billing_info" => [],
               "payments" => []
             }
    end

    test "returns proper payment-blocked status when approved", ~M[conn] do
      conn = get(conn, Routes.user_api_v1_payment_path(conn, :index))

      assert json_response(conn, 200) == %{
               "block_online_payments" => false,
               "billing_info" => [],
               "payments" => []
             }
    end
  end

  describe "create - DEPRECATED" do
    setup(~M[conn]) do
      account =
        insert(:user_account)
        |> AppCount.UserHelper.new_account()

      payment_source = insert(:payment_source, account: account)
      params = %{"payment" => %{"amount" => "12.34", "payment_source_id" => payment_source.id}}

      ~M[conn, account, params]
    end

    @tag :slow
    test "Authentication Failed", ~M[conn] do
      params = %{"payment" => "params"}
      # When
      conn = post(conn, Routes.user_api_v1_payment_path(conn, :create), params)

      assert json_response(conn, 401) == %{"error" => "Authentication Failed"}
    end

    @tag :slow
    test "prompts to upgrade when authentication succeeds", ~M[conn, account, params] do
      conn = user_mobile_request(conn, account)
      conn = post(conn, Routes.user_api_v1_payment_path(conn, :create), params)

      assert json_response(conn, 400) == %{
               "error" => "Please update the AppRent app to the latest version and try again."
             }
    end
  end
end
