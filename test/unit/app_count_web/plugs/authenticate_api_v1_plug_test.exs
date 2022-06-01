defmodule AppCountWeb.Plugs.AuthenticateAPIV1PlugTest do
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

  test "authentication fails with no token", ~M[conn] do
    conn =
      bypass_through(conn, AppCountWeb.Router, [:public_api])
      |> get("/")
      |> AppCountWeb.AuthenticateAPIV1Plug.call([])

    assert conn.halted
    assert conn.resp_body =~ "Authentication Failed"
  end

  test "authentication passes with x-admin-token", ~M[conn, admin] do
    token = AppCountWeb.Token.token(auth_user_struct(admin))

    conn =
      bypass_through(conn, AppCountWeb.Router, [:public_api])
      |> get("/")
      |> put_req_header("x-admin-token", token)
      |> AppCountWeb.AuthenticateAPIV1Plug.call([])

    assert not is_nil(conn.assigns.admin)
    assert conn.assigns.user.id == admin.id
  end
end
