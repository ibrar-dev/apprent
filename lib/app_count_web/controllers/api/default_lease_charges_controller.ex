defmodule AppCountWeb.API.DefaultLeaseChargesController do
  use AppCountWeb, :controller
  alias AppCount.Units

  authorize(["Super Admin", "Regional", "Admin"])

  def index(conn, %{"unit_id" => unit_id}) do
    json(conn, Units.default_charges(unit_id))
  end

  def create(conn, %{"newCharges" => params}) do
    Units.multi_create_default_charges(params)
    |> handle_error(conn)
  end

  def create(conn, %{"charge" => params}) do
    Units.create_default_charge(params)
    json(conn, %{})
  end

  def create(conn, %{
        "clone" => _,
        "floor_plan_id" => initial_floor_plan_id,
        "target_floor_plan_id" => target_floor_plan_id
      }) do
    Units.clone_charges(initial_floor_plan_id, target_floor_plan_id)
    json(conn, %{})
  end

  def update(conn, %{"charges" => params}) do
    Units.update_default_charges(params)
    |> handle_error(conn)
  end

  def update(conn, %{"id" => id, "charge" => params}) do
    Units.update_default_charge(id, params)
    json(conn, %{})
  end

  def delete(conn, %{"id" => id}) do
    Units.delete_default_charge(id)
    json(conn, %{})
  end
end
