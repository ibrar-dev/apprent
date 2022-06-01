defmodule AppCountWeb.Controllers.API.CardItemControllerTest do
  use AppCount.Case
  use AppCountWeb.ConnCase
  alias AppCount.Support.PropertyBuilder, as: PropBuilder
  alias AppCount.Core.CardItemTopic
  @moduletag :card_item_controller

  setup do
    CardItemTopic.subscribe()

    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_admin_with_access()
      |> PropBuilder.add_card()
      |> PropBuilder.add_card_item()

    admin = PropBuilder.get_requirement(builder, :admin)
    item = PropBuilder.get_requirement(builder, :card_item)

    ~M[admin, item]
  end

  @tag subdomain: "administration"
  test "create", ~M[admin, conn] do
    params = %{
      "card_item" => %{
        "Fake_card_items" => "fakey mcfakerson fake values",
        "card_id" => insert(:card).id,
        "name" => "Some Name"
      }
    }

    conn =
      conn
      |> admin_request(admin)
      |> post(Routes.api_card_item_path(conn, :create, params))

    assert json_response(conn, 200) == %{}
  end

  @tag subdomain: "administration"
  test "update", ~M[admin, conn, item] do
    params = %{"scheduled" => "2022-01-01"}

    conn =
      conn
      |> admin_request(admin)
      |> patch(Routes.api_card_item_path(conn, :update, item.id), %{"card_item" => params})

    assert json_response(conn, 200) == %{}
  end

  @tag subdomain: "administration"
  test "update completed", ~M[admin, conn, item] do
    params = %{"admin_id" => admin.id}

    conn =
      conn
      |> admin_request(admin)
      |> patch(
        Routes.api_card_item_path(conn, :update, item.id),
        %{"card_item" => params, "complete" => true}
      )

    assert json_response(conn, 200) == %{}
  end

  @tag subdomain: "administration"
  test "update reverted", ~M[admin, conn, item] do
    params = %{"admin_id" => admin.id}

    conn =
      conn
      |> admin_request(admin)
      |> patch(
        Routes.api_card_item_path(conn, :update, item.id),
        %{"card_item" => params, "revert" => true}
      )

    assert json_response(conn, 200) == %{}
  end

  @tag subdomain: "administration"
  test "update confirmed", ~M[admin, conn, item] do
    params = %{"admin_id" => admin.id}

    conn =
      conn
      |> admin_request(admin)
      |> patch(
        Routes.api_card_item_path(conn, :update, item.id),
        %{"card_item" => params, "confirm" => true}
      )

    assert json_response(conn, 200) == %{}
  end
end
