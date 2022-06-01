defmodule AppCountAuth.API.RoleController do
  use AppCountAuth, :request

  def index(admin, _params) do
    auth_checks(admin, super_admin: true)
  end

  def create(admin, _params) do
    auth_checks(admin, super_admin: true)
  end

  def update(admin, _params) do
    auth_checks(admin, super_admin: true)
  end

  def delete(admin, _params) do
    auth_checks(admin, super_admin: true)
  end
end
