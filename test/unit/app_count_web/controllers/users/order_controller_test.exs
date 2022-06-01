defmodule AppCountWeb.Controllers.Users.OrderControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Maintenance
  alias AppCount.Repo
  @moduletag :users_order_controller

  setup do
    account =
      insert(:user_account)
      |> AppCount.UserHelper.new_account()

    insert(:tenancy, tenant: account.tenant)
    {:ok, account: account}
  end

  test "user orders page loads", %{conn: conn, account: account} do
    response =
      conn
      |> user_request(account)
      |> get("http://residents.example.com/work_orders")
      |> html_response(200)

    assert response =~ "#{account.tenant.first_name} #{account.tenant.last_name}"
    assert response =~ "Maintenance Orders"
  end

  test "user new order page loads", %{conn: conn, account: account} do
    insert(:category)
    cat1 = insert(:sub_category)
    cat2 = insert(:sub_category)

    response =
      conn
      |> user_request(account)
      |> get("http://residents.example.com/work_orders/new")
      |> html_response(200)

    assert response =~ "#{account.tenant.first_name} #{account.tenant.last_name}"
    assert response =~ cat1.name
    assert response =~ cat2.name
  end

  test "user create order works", %{conn: conn, account: account} do
    category = insert(:category)

    params = %{
      "category_id" => category.id,
      "entry_allowed" => "true",
      "has_pet" => "true",
      "notes" => "Special Unique NOTE"
    }

    redirect =
      conn
      |> user_request(account)
      |> post("http://residents.example.com/work_orders", order: params)
      |> redirected_to()

    assert redirect == "/work_orders"

    new_order =
      Repo.get_by(Maintenance.Order, category_id: category.id, tenant_id: account.tenant.id)
      |> Repo.preload(:notes)

    assert new_order
    assert new_order
    assert hd(new_order.notes).text == "Special Unique NOTE"
  end

  test "user edit order page loads", %{conn: conn, account: account} do
    order = insert(:order, tenant: account.tenant)

    response =
      conn
      |> user_request(account)
      |> get("http://residents.example.com/work_orders/#{order.id}/edit")
      |> html_response(200)

    assert response =~ order.ticket
  end

  test "user update order works", %{conn: conn, account: account} do
    order = insert(:order, tenant: account.tenant)
    category = insert(:sub_category)
    note = "Updated Note - #{category.id}"

    params = %{
      "category_id" => category.id,
      "entry_allowed" => "true",
      "has_pet" => "true",
      "notes" => note
    }

    redirect =
      conn
      |> user_request(account)
      |> patch("http://residents.example.com/work_orders/#{order.id}", order: params)
      |> redirected_to()

    assert redirect == "/work_orders"

    new_order =
      Repo.get(Maintenance.Order, order.id)
      |> Repo.preload(:notes)

    assert new_order.category_id == category.id
    assert hd(new_order.notes).text == note
  end

  test "user update order error handling", %{conn: conn, account: account} do
    order = insert(:order, tenant: account.tenant)
    params = %{"category_id" => nil, "has_pet" => "true", "notes" => "Special Unique NOTE"}

    new_conn =
      conn
      |> user_request(account)
      |> patch("http://residents.example.com/work_orders/#{order.id}", order: params)

    assert get_flash(new_conn)["error"] == "Category can't be blank"
    assert redirected_to(new_conn) == "/work_orders/#{order.id}/edit"
  end

  test "user delete order works", %{conn: conn, account: account} do
    order = insert(:order, tenant: account.tenant)

    new_conn =
      conn
      |> user_request(account)
      |> delete("http://residents.example.com/work_orders/#{order.id}")

    refute Repo.get(Maintenance.Order, order.id)
    assert redirected_to(new_conn) == "/work_orders"
  end
end
