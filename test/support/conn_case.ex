defmodule AppCountWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common datastructures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """
  alias AppCount.Core.ClientSchema
  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use AppCount.DataCase
      import Plug.Conn
      import Phoenix.ConnTest
      import ShorterMaps

      alias AppCount.Core.Clock
      alias AppCountWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint AppCountWeb.Endpoint

      def auth_user_struct(admin) do
        # TODO awkward stuff here with roles, is going away soon
        to_merge =
          Map.take(admin, [:email, :features, :id, :name, :property_ids, :roles, :schema])
          |> Map.put(:roles, MapSet.new(Map.get(admin, :roles, [])))

        params =
          %{
            client_schema: "dasmen",
            features: ["core", "maintenance", "applications", "tenant_portal", "rewards"],
            id: 1,
            roles: MapSet.new([]),
            email: "somebody@example.com",
            name: "Nice admin",
            property_ids: []
          }
          |> Map.merge(to_merge)

        struct(AppCountAuth.Users.Admin, params)
      end

      def apprent_admin_request(conn) do
        admin = %AppCountAuth.Users.AppRent{id: 1, username: "Super Duper Admin"}

        Plug.Test.init_test_session(
          conn,
          apprent_manager_token: AppCountWeb.Token.token(admin)
        )
      end

      def admin_request(conn, admin) do
        Plug.Test.init_test_session(
          conn,
          admin_token: AppCountWeb.Token.token(auth_user_struct(admin))
        )
      end

      def admin_api_request(conn, admin) do
        Plug.Conn.put_req_header(
          conn,
          "x-admin-token",
          AppCountWeb.Token.token(auth_user_struct(admin))
        )
      end

      def user_request(conn, account) do
        # token =
        #   AppCountWeb.Token.token(%{
        #     tenant_account_id: account.id,
        #     account_id: account.id,
        #     user_id: account.user.id,
        #     schema: account.user.client.client_schema
        #   })
        token =
          AppCount.Public.Auth.get_tenant_data(
            "Tenant",
            ClientSchema.new(account.user.client.client_schema, account.user)
          )
          |> AppCountWeb.Token.token()

        Plug.Test.init_test_session(
          conn,
          user_token: token
        )
      end

      def user_mobile_request(conn, account) do
        token =
          AppCount.Public.Auth.get_tenant_data(
            "Tenant",
            ClientSchema.new(account.user.client.client_schema, account.user)
          )
          |> AppCountWeb.Token.token()

        conn
        |> Plug.Conn.put_req_header("x-user-token", token)
        |> Plug.Test.init_test_session([])
      end
    end
  end

  setup do
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  setup tags do
    # [ecto setup]
    conn = setup_conn_with_host(tags[:subdomain] || "www")
    {:ok, conn: conn}
  end

  defp setup_conn_with_host(subdomain) do
    host = "#{subdomain}." <> AppCountWeb.Endpoint.config(:url)[:host]
    Phoenix.ConnTest.build_conn(:get, "http://#{host}/", nil)
  end
end
