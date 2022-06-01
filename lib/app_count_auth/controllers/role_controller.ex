defmodule AppCountAuth.RoleController do
  use AppCountAuth, :request

  def index(admin, _params) do
    auth_checks(admin, super_admin: true)
  end
end
