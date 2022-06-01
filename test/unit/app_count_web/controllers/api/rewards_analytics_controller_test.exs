defmodule AppCountWeb.API.RewardsAnalyticsControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Tenants.Tenant
  alias AppCount.Tenants.TenantRepo

  def create_tenant() do
    {:ok, tenant} =
      Tenant.new("Mickey", "Mouse")
      |> Map.from_struct()
      |> TenantRepo.insert()

    tenant
  end

  defmodule RewardsBoundaryParrot do
    use TestParrot
    # client = AppCount.Public.get_client_by_schema("dasmen")

    parrot(:rewards_boundary, :list_cards, reward_analytics([999]))

    def reward_analytics(properties) when is_list(properties) do
      type = ["Autopay"]
      purchase = ["Renew Lease"]
      tenants = ["John", "Paul", "Ringo", "George"]

      %{
        most_frequent_accomplishment_type: %{ytd: type, mtd: type},
        high_scoring_tenants: %{ytd: tenants, mtd: tenants},
        most_purchased_reward_names: %{ytd: purchase, mtd: purchase}
      }
    end
  end

  setup do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_factory_admin()

    property = PropBuilder.get_requirement(builder, :property)
    admin = PropBuilder.get_requirement(builder, :admin)

    ~M[admin, property, builder]
  end

  @tag subdomain: "administration"
  test "index infoBox one property", ~M[conn, admin, property] do
    create_tenant()

    property_id_string = "#{property.id}"
    params = %{"infoBox" => "irrelvant info", "properties" => property_id_string}

    conn =
      conn
      |> assign(:rewards_boundary, RewardsBoundaryParrot)
      |> admin_request(admin)

    # When
    conn = get(conn, Routes.api_rewards_analytics_path(conn, :index, params))

    assert json_response(conn, 200)
    result = json_response(conn, 200)

    # Main Keys
    assert result["most_frequent_accomplishment_type"]
    assert result["high_scoring_tenants"]
    assert result["most_purchased_reward_names"]

    assert result["most_frequent_accomplishment_type"]["ytd"] == ["Autopay"]
    assert result["most_frequent_accomplishment_type"]["mtd"] == ["Autopay"]

    assert result["high_scoring_tenants"]["ytd"] == ["John", "Paul", "Ringo", "George"]
    assert result["high_scoring_tenants"]["mtd"] == ["John", "Paul", "Ringo", "George"]

    assert result["most_purchased_reward_names"]["ytd"] == ["Renew Lease"]
    assert result["most_purchased_reward_names"]["mtd"] == ["Renew Lease"]
  end

  @tag subdomain: "administration"
  test "index infoBox TWO properties", ~M[conn, admin, property] do
    create_tenant()

    properties_id_string = "#{property.id},#{property.id}"
    params = %{"infoBox" => "irrelvant info", "properties" => properties_id_string}

    conn =
      conn
      |> assign(:rewards_boundary, RewardsBoundaryParrot)
      |> admin_request(admin)

    # When
    conn = get(conn, Routes.api_rewards_analytics_path(conn, :index, params))

    assert json_response(conn, 200)
    result = json_response(conn, 200)

    # Main Keys
    assert result["most_frequent_accomplishment_type"]
    assert result["high_scoring_tenants"]
    assert result["most_purchased_reward_names"]
  end
end
