defmodule AppCount.Public.AuthTest do
  use AppCount.DataCase
  alias AppCount.Public.Auth
  alias AppCount.Core.ClientSchema

  describe "get_tenant_data/3" do
    setup do
      account =
        insert(:user_account)
        |> AppCount.UserHelper.new_account()

      user = account.user

      ~M[user]
    end

    test "Admin" do
      %{user: user, id: id, email: email, name: name} = AppCount.UserHelper.new_admin()

      # When
      result = Auth.get_tenant_data("Admin", %ClientSchema{name: "dasmen", attrs: user})

      assert %AppCountAuth.Users.Admin{
               client_schema: "dasmen",
               features: %{},
               id: ^id,
               roles: %{},
               email: ^email,
               name: ^name,
               property_ids: []
             } = result
    end

    test "Tenant", ~M[user] do
      # When
      result = Auth.get_tenant_data("Tenant", ClientSchema.new("dasmen", user))

      assert %AppCountAuth.Users.Tenant{
               account_id: _,
               alarm_code: nil,
               autopay: false,
               client_schema: "dasmen",
               email: _,
               features: nil,
               first_name: _,
               id: _,
               last_name: "Smith",
               name: _,
               password_changed: false,
               payment_status: "approved",
               phone: nil,
               preferred_language: "english",
               profile_pic: nil,
               property: %{icon: nil, id: _, logo: nil, name: "Test Property"},
               receives_mailings: true,
               tenant_account_id: _,
               user_id: _,
               uuid: _
             } = result
    end

    test "AppRent" do
      user = %{id: 99, username: "Ringo"}
      # When
      result = Auth.get_tenant_data("AppRent", ClientSchema.new("dasmen", user))

      assert %AppCountAuth.Users.AppRent{id: 99, username: "Ringo"} = result
    end

    test "Tech" do
      user = nil
      # When
      result = Auth.get_tenant_data("Tech", ClientSchema.new("dasmen", user))
      assert result == nil
    end
  end

  describe "refresh_user/1" do
    test "refresh_user/1 for admins" do
      admin = AppCount.UserHelper.new_admin()

      auth_struct =
        Auth.get_tenant_data("Admin", %ClientSchema{name: "dasmen", attrs: admin.user})

      # make sure property_ids is empty beforehand
      assert auth_struct.property_ids == []
      property = insert(:property)
      region = insert(:region)
      insert(:scoping, property_id: property.id, region_id: region.id)
      insert(:permission, region: region, admin: admin)

      # When
      refreshed_auth_struct = Auth.refresh_user(auth_struct)
      assert refreshed_auth_struct.property_ids == [property.id]
    end

    test "refresh_user/1 for tenants" do
      %{user: user, tenant: tenant} =
        insert(:user_account)
        |> AppCount.UserHelper.new_account()

      auth_struct = Auth.get_tenant_data("Tenant", %ClientSchema{name: "dasmen", attrs: user})
      assert auth_struct.email == tenant.email

      AppCount.Tenants.TenantRepo.update(tenant, %{email: "Joke@example.com"}, prefix: "dasmen")

      assert Auth.refresh_user(auth_struct).email == "Joke@example.com"
    end
  end
end
