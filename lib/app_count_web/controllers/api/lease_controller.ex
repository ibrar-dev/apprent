defmodule AppCountWeb.API.LeaseController do
  use AppCountWeb, :controller
  alias AppCount.Leases
  alias AppCount.Leasing
  alias AppCount.Core.ClientSchema

  def show(conn, %{"id" => id} = params) do
    json(conn, Leasing.BlueMoon.Renewals.renewal_params(id, params))
  end

  def create(conn, %{"bluemoon_params" => params}) do
    params
    |> Map.put("admin", Map.from_struct(conn.assigns.admin))
    |> BlueMoon.Data.Lease.cast_params()
    |> Map.put(:default_lease_charges, params["default_lease_charges"])
    |> Leasing.BlueMoon.CreateLease.create()
    |> handle_error(conn)
  end

  #  def create(conn, %{"no_renewal_ids" => lease_ids}) do
  #    Leases.update_leases(lease_ids, %{no_renewal: true})
  #    json(conn, %{})
  #  end

  def create(conn, %{"lease" => params}) do
    Leases.create_lease(ClientSchema.new(conn.assigns.client_schema, params))
    |> handle_error(conn)
  end

  def create(conn, %{"lease_ids" => lease_ids, "params" => params}) do
    Leases.update_leases(lease_ids, ClientSchema.new(conn.assigns.client_schema, params))
    json(conn, %{})
  end

  def update(conn, %{"id" => id, "lock" => params}) do
    Leases.lock_lease(id, Map.put(params, "admin", conn.assigns.admin.name))
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "unlock" => _}) do
    Leases.unlock_lease(id)
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "lease" => params}) do
    Leases.update_lease(
      id,
      ClientSchema.new(
        conn.assigns.client_schema,
        Map.put(params, "admin", conn.assigns.admin.name)
      )
    )
    |> handle_error(conn)
  end

  def delete(conn, %{"id" => id}) do
    Leases.delete_lease(conn.assigns.admin, id)
    json(conn, %{})
  end
end
