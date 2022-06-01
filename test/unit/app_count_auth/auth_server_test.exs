defmodule AppCountAuth.AuthServerTest do
  use AppCount.Case
  alias AppCountAuth.AuthServer

  setup do
    admin = %AppCountAuth.Users.Admin{
      client_schema: "dasmen",
      id: 1
    }

    tenant = %AppCountAuth.Users.Tenant{
      client_schema: "dasmen",
      id: 11
    }

    on_exit(&AuthServer.reset/0)
    {:ok, admin: admin, tenant: tenant}
  end

  test "blocks users", %{admin: admin, tenant: tenant} do
    assert AuthServer.get_status(admin) == :pass
    AuthServer.block(admin)
    assert AuthServer.get_status(admin) == :block

    assert AuthServer.get_status(tenant) == :pass
    AuthServer.block(tenant)
    assert AuthServer.get_status(tenant) == :block
  end

  test "sets forced login status", %{admin: admin, tenant: tenant} do
    assert AuthServer.get_status(admin) == :pass
    AuthServer.force_new_login(admin)
    assert AuthServer.get_status(admin) == :logout

    assert AuthServer.get_status(tenant) == :pass
    AuthServer.force_new_login(tenant)
    assert AuthServer.get_status(tenant) == :logout
  end

  test "sets forced token refresh status", %{admin: admin, tenant: tenant} do
    assert AuthServer.get_status(admin) == :pass
    AuthServer.force_token_refresh(admin)
    assert AuthServer.get_status(admin) == :refresh

    assert AuthServer.get_status(tenant) == :pass
    AuthServer.force_token_refresh(tenant)
    assert AuthServer.get_status(tenant) == :refresh
  end

  test "sets status back to pass", %{admin: admin} do
    AuthServer.force_token_refresh(admin)
    assert AuthServer.get_status(admin) == :refresh
    AuthServer.set_pass(admin)
    assert AuthServer.get_status(admin) == :pass
  end
end
