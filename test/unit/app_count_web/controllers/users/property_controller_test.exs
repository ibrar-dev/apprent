defmodule AppCountWeb.Controllers.Users.PropertyControllerTest do
  use AppCountWeb.ConnCase
  @moduletag :property_controller
  alias AppCount.Core.ClientSchema

  setup do
    account =
      insert(:user_account)
      |> AppCount.UserHelper.new_account()

    property = insert(:tenancy, tenant: account.tenant).unit.property

    {:ok, property} =
      AppCount.Properties.update_property(
        property.id,
        ClientSchema.new(
          account.user.client.client_schema,
          %{address: %{street: "123 Sesame St."}}
        )
      )

    {:ok, account: account, property: property}
  end

  test "user property page loads", %{conn: conn, account: account, property: property} do
    user_property_id = %{
      assigns: %{
        user: %{
          property: %{
            id: property.id
          }
        }
      }
    }

    conn = Map.merge(conn, user_property_id)

    response =
      conn
      |> user_request(account)
      |> get("http://residents.example.com/property")
      |> html_response(200)

    assert response =~ "3317 Magnolia Hill Dr"
  end
end
