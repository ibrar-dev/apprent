defmodule AppCountWeb.Controllers.API.FinanceAccountControllerTest do
  use AppCountWeb.ConnCase, async: true

  defmodule FinanceBoundaryParrot do
    use TestParrot

    def fake_account do
      %AppCount.Finance.Account{
        name: "Some Account",
        number: "12345678",
        natural_balance: "credit",
        type: "Asset",
        subtype: "Fixed Asset",
        description: "This is an account",
        id: 123
      }
    end

    parrot(:finance_boundary, :list_accounts, {:ok, []})
    parrot(:finance_boundary, :create_account, {:ok, fake_account()})
    parrot(:finance_boundary, :get_account, {:ok, fake_account()})
  end

  setup(~M[conn]) do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_super_admin()

    admin = PropBuilder.get_requirement(builder, :admin)

    conn =
      conn
      |> assign(:finance_boundary, FinanceBoundaryParrot)
      |> admin_request(admin)

    ~M[conn]
  end

  describe "create/2" do
    @tag subdomain: "administration"
    test "succeeds", ~M[conn] do
      params = %{
        name: "Some Account",
        number: "12345678",
        natural_balance: "credit",
        type: "Asset",
        subtype: "Fixed Asset",
        description: "This is an account"
      }

      conn =
        conn
        |> post(Routes.api_finance_account_path(conn, :create), params)

      assert body = json_response(conn, 201)

      assert body == %{
               "data" => %{
                 "name" => "Some Account",
                 "number" => "12345678",
                 "natural_balance" => "credit",
                 "type" => "Asset",
                 "subtype" => "Fixed Asset",
                 "description" => "This is an account",
                 "id" => 123
               }
             }
    end

    @tag subdomain: "administration"
    test "fails", ~M[conn] do
      error_changeset = AppCount.Finance.Account.changeset(%AppCount.Finance.Account{}, %{})
      FinanceBoundaryParrot.say_create_account({:error, error_changeset})

      bad_params = %{}

      conn =
        conn
        |> post(Routes.api_finance_account_path(conn, :create), bad_params)

      assert body = json_response(conn, 400)

      assert is_map(body["error"])
    end
  end

  describe "show/2" do
    @tag subdomain: "administration"
    test "succeeds", ~M[conn] do
      conn =
        conn
        |> get(Routes.api_finance_account_path(conn, :show, 123))

      assert json_response(conn, 200) == %{
               "data" => %{
                 "name" => "Some Account",
                 "number" => "12345678",
                 "natural_balance" => "credit",
                 "type" => "Asset",
                 "subtype" => "Fixed Asset",
                 "description" => "This is an account",
                 "id" => 123
               }
             }
    end

    @tag subdomain: "administration"
    test " fails", ~M[conn] do
      FinanceBoundaryParrot.say_get_account({:error, "Not Found"})

      conn =
        conn
        |> get(Routes.api_finance_account_path(conn, :show, 123))

      assert json_response(conn, 404) == %{"errors" => ["Not Found"]}
    end
  end

  describe "index/2" do
    @tag subdomain: "administration"
    test "succeeds", ~M[conn] do
      conn =
        conn
        |> get(Routes.api_finance_account_path(conn, :index))

      assert body = json_response(conn, 200)
      assert body == %{"data" => []}
    end
  end
end
