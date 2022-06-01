defmodule AppCountWeb.Controllers.API.CardControllerTest do
  use AppCount.Case
  use AppCountWeb.ConnCase
  alias AppCount.Core.CardTopic
  alias AppCount.Support.PropertyBuilder, as: PropBuilder
  @moduletag :card_controller

  defmodule MaintenanceParrot do
    use TestParrot
    parrot(:maintenance, :list_cards, ["something"])
    parrot(:maintenance, :list_last_domain_event, {:ok, %{subject_id: 44}})

    parrot(:maintenance, :update_card, %{
      "id" => 555,
      "card" => %{"completion_status" => "completed"}
    })

    parrot(:maintenance, :create_card, %{test_card: "Hello"})
  end

  setup do
    CardTopic.subscribe()

    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_factory_admin()

    unit1 = PropBuilder.get_requirement(builder, :unit)
    property = PropBuilder.get_requirement(builder, :property)
    admin = PropBuilder.get_requirement(builder, :admin)

    ~M[admin, property, unit1, builder]
  end

  @tag subdomain: "administration"
  test "index for active cards", ~M[conn, admin, builder] do
    card_attrs = [hidden: false]

    builder =
      builder
      |> PropBuilder.add_card(card_attrs)

    property = PropBuilder.get_requirement(builder, :property)

    params = %{
      "property_ids" => "#{property.id}",
      "hidden_cards" => "false"
    }

    conn = conn |> admin_request(admin)
    # When
    conn = get(conn, Routes.api_card_path(conn, :index, params))

    assert json_response(conn, 200) == []
  end

  @tag subdomain: "administration"
  test "index for hidden cards", %{admin: admin, conn: conn, unit1: _unit} do
    card_attrs = [hidden: true]

    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_card(card_attrs)

    property = PropBuilder.get_requirement(builder, :property)

    params = %{
      "property_ids" => "#{property.id}",
      "hidden_cards" => "true"
    }

    conn = conn |> admin_request(admin)
    # When
    conn = get(conn, Routes.api_card_path(conn, :index, params))

    assert json_response(conn, 200) == []
  end

  @tag subdomain: "administration"
  test "index with just property IDs", %{admin: admin, conn: conn, unit1: _unit} do
    card_attrs = [hidden: true]

    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_unit()
      |> PropBuilder.add_card(card_attrs)

    property = PropBuilder.get_requirement(builder, :property)

    params = %{
      "property_ids" => "#{property.id}"
    }

    conn = conn |> admin_request(admin)
    # When
    conn = get(conn, Routes.api_card_path(conn, :index, params))

    assert json_response(conn, 200) == []
  end

  @tag subdomain: "administration"
  test "get() with boundry", ~M[conn, admin] do
    conn = assign(conn, :maintenance, MaintenanceParrot)
    conn = conn |> admin_request(admin)

    params = %{
      "property_ids" => "191919,22020",
      "hidden_cards" => "true"
    }

    # When
    conn = get(conn, Routes.api_card_path(conn, :index, params))

    assert json_response(conn, 200) == ["something"]
    assert_receive {:list_cards, _admin, ["191919", "22020"], :hidden}
  end

  @tag subdomain: "administration"
  test "create", %{admin: %{name: admin_name} = admin, conn: conn, unit1: unit} do
    deadline = Timex.shift(AppCount.current_date(), days: 17)
    move_out_date = Timex.shift(AppCount.current_date(), days: 7)
    id = unit.id

    params = %{
      "unit_id" => id,
      "move_out_date" => move_out_date,
      "deadline" => deadline
    }

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)
      |> post(Routes.api_card_path(conn, :create), %{"card" => params})

    assert json_response(conn, 200) == %{}

    assert_receive {:create_card,
                    %{
                      "admin" => ^admin_name,
                      "deadline" => ^deadline,
                      "move_out_date" => ^move_out_date,
                      "unit_id" => ^id
                    }}
  end

  @tag subdomain: "administration"
  test "update for complete card", %{admin: admin, conn: conn} do
    id = 555
    deadline = Timex.shift(AppCount.current_date(), days: 17)
    params = %{"deadline" => deadline}

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)
      |> patch(Routes.api_card_path(conn, :update, id), %{"card" => params})

    id = "#{id}"
    assert json_response(conn, 200) == %{}
    assert_receive {:update_card, ^id, %{"deadline" => ^deadline}}
  end

  @tag subdomain: "administration"
  test "update for incomplete card", %{admin: admin, conn: conn} do
    MaintenanceParrot.say_update_card(%{
      "id" => 555,
      "card" => %{"completion_status" => "incomplete"}
    })

    id = 555
    deadline = Timex.shift(AppCount.current_date(), days: 17)
    params = %{"deadline" => deadline}

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)
      |> patch(Routes.api_card_path(conn, :update, id), %{"card" => params})

    id = "#{id}"
    assert json_response(conn, 200) == %{}
    assert_receive {:update_card, ^id, %{"deadline" => ^deadline}}
  end

  @tag subdomain: "administration"
  test "last_domain_event, success", %{admin: admin, conn: conn, unit1: _unit} do
    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    params = %{
      "card_ids" => "123,345"
    }

    conn = get(conn, Routes.api_card_path(conn, :show, "last_domain_event", params))

    assert json_response(conn, 200) == %{"subject_id" => 44}
    assert_receive {:list_last_domain_event, ["123", "345"]}
  end

  @tag subdomain: "administration"
  test "last_domain_event with zero events", %{admin: admin, conn: conn, unit1: _unit} do
    MaintenanceParrot.say_list_last_domain_event(%{})

    conn =
      assign(conn, :maintenance, MaintenanceParrot)
      |> admin_request(admin)

    params = %{
      "card_ids" => nil
    }

    conn = get(conn, Routes.api_card_path(conn, :show, "last_domain_event", params))

    assert_receive {:list_last_domain_event, [""]}
    assert json_response(conn, 200) == %{}
  end
end
