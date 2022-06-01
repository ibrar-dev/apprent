defmodule AppCount.Auth.AuthCase do
  use AppCountWeb.ConnCase
  alias AppCount.Auth.Users.Admin

  test "Auth invokes underlying function with correct arguments on valid authorization", %{
    conn: conn
  } do
    boundary_func = fn client_name, admin, :min ->
      assert client_name == "testing"
      assert admin.name == "Ed"
      ["fake property"]
    end

    admin = %Admin{client: "testing", name: "Ed"}

    resp =
      conn
      |> assign(:user, admin)
      |> assign(:boundary, boundary_func)
      |> AppCount.Auth.invoke({AppCount.Properties, :list_properties, [admin, :min]})

    assert resp == ["fake property"]
  end

  test "Auth returns error tuple and does not invoke function on invalid authorization", %{
    conn: conn
  } do
    boundary_func = fn _, _ ->
      flunk("function should not be called")
    end

    admin = %Admin{client: "testing", name: "Ed"}

    resp =
      conn
      |> assign(:user, admin)
      |> assign(:boundary, boundary_func)
      |> AppCount.Auth.invoke({AppCount.Properties, :list_properties, [admin]})

    assert resp == {:error, :unauthorized}
  end
end
