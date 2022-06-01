defmodule AppCountWeb.Plugs.AuthorizePlugTest do
  use AppCountWeb.ConnCase
  use AppCount.Case
  alias AppCount.Support.PropertyBuilder, as: PropBuilder

  setup do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_factory_admin()

    admin = PropBuilder.get_requirement(builder, :admin)

    ~M[admin]
  end

  test "Authenticate user and check for Authorization for session controller", ~M[conn, admin] do
    token = AppCountWeb.Token.token(admin.uuid)

    conn =
      put_private(conn, :phoenix_controller, Module.concat(["AppCountAuth.SessionController"]))

    conn = put_private(conn, :phoenix_action, :create)

    conn =
      bypass_through(conn, AppCountWeb.Router, [:public_api])
      |> get("/")
      |> put_req_header("x-admin-token", token)
      |> assign(:user, admin)
      |> AppCountWeb.AuthorizationPlug.call([])

    assert not conn.halted
  end
end
