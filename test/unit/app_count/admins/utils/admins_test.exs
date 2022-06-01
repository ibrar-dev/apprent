defmodule AppCount.Admins.Utils.AdminsTest do
  use AppCount.DataCase
  alias AppCount.Admins.Utils.Admins
  alias AppCount.Core.ClientSchema

  setup do
    builder =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_admin()

    admin = PropBuilder.get_requirement(builder, :admin)
    ~M[admin]
  end

  describe "create_admin/1" do
    test "succeeds" do
      client = AppCount.Public.get_client_by_schema("dasmen")

      {:ok, admin} =
        ClientSchema.new(
          client.client_schema,
          %{
            "email" => "admin@example.com",
            "password" => "password",
            "name" => "Dev Admin",
            "username" => "Admin",
            "permissions" => AppCount.Admins.Auth.Permissions.super_admin()
          }
        )
        |> AppCount.Admins.Utils.Admins.create_admin()

      admin = Repo.preload(admin, :public_user, prefix: "public")

      assert admin.email == "admin@example.com"
      assert admin.username == "Admin"
      assert admin.public_user.username == "Admin"
      assert admin.public_user_id
    end
  end

  describe "update/2" do
    test "deactivates an admin", ~M[admin] do
      changeset = %{active: false}

      {:ok, post_update_admin} =
        Admins.update_admin(
          admin.id,
          ClientSchema.new(
            admin.user.client.client_schema,
            changeset
          )
        )

      assert admin.active
      refute post_update_admin.active
    end
  end
end
