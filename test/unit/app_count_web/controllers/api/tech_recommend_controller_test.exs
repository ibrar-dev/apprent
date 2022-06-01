defmodule AppCountWeb.API.TechRecommendControllerTest do
  use AppCount.Case
  use AppCountWeb.ConnCase
  alias AppCount.Support.PropertyBuilder, as: PropBuilder

  defmodule TechRecommendBoundaryParrot do
    use TestParrot
    parrot(:tech_recommend, :recommend, [])
  end

  setup do
    [_builder, admin] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_factory_admin()
      |> PropBuilder.get([:admin])

    ~M[admin]
  end

  @tag subdomain: "administration"
  test "request recommendation of no one", ~M[conn, admin] do
    work_order_id = 99
    params = %{"work_order_id" => work_order_id}

    conn =
      assign(conn, :tech_recommend_boundary, TechRecommendBoundaryParrot)
      |> admin_request(admin)

    # When
    conn = get(conn, Routes.api_tech_recommend_path(conn, :index, params))

    assert json_response(conn, 200) == %{
             "data" => []
           }

    assert_receive {:recommend, ^work_order_id}
  end

  @tag subdomain: "administration"
  test "request recommendation of ringo", ~M[conn, admin] do
    work_order_id = 99
    params = %{"work_order_id" => work_order_id}

    ringo_the_tech = %AppCount.Maintenance.Tech{name: "Ringo Starr"}
    recommended_techs = [ringo_the_tech]
    TechRecommendBoundaryParrot.say_recommend(recommended_techs)

    conn =
      assign(conn, :tech_recommend_boundary, TechRecommendBoundaryParrot)
      |> admin_request(admin)

    # When
    conn = get(conn, Routes.api_tech_recommend_path(conn, :index, params))

    assert json_response(conn, 200) == %{
             "data" => [%{"tech_id" => nil, "tech_name" => "Ringo Starr"}]
           }

    assert_receive {:recommend, ^work_order_id}
  end
end
