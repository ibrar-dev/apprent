defmodule AppCount.AdminsFactory do
  use ExMachina.Ecto, repo: AppCount.Repo

  defmacro __using__(_opts) do
    quote do
      def admin_with_access(property_ids, admin_options \\ []) do
        admin = insert(:admin, admin_options)

        client = AppCount.Public.get_client_by_schema("dasmen")

        user_params =
          Map.merge(Map.from_struct(admin), %{
            type: "Admin",
            tenant_account_id: admin.id,
            password: "test_password",
            client_id: client.id,
            username: admin.email
          })

        # create and load user and client data
        user =
          case AppCount.Public.Accounts.create_user(user_params) do
            {:ok, user} ->
              AppCount.Public.Accounts.get_user!(user.id)
          end

        admin = Map.put(admin, :user, user)

        entity = insert(:region)

        property_ids
        |> Enum.each(&insert(:scoping, property_id: &1, region_id: entity.id))

        insert(:permission, admin_id: admin.id, region_id: entity.id)

        admin
      end

      def org_chart_factory do
        admin = AppCount.UserHelper.new_admin()

        %AppCount.Admins.OrgChart{
          admin: admin
        }
      end

      def admin_factory do
        %AppCount.Admins.Admin{
          email: sequence(:email, &"admin#{&1}@example.com"),
          name: sequence(:name, &"Admin#{&1} Adminson"),
          username: sequence(:username, &"AdminGuy#{&1}"),
          password_hash: "password",
          roles: ["Admin"],
          uuid: UUID.uuid4()
        }
      end

      def region_factory do
        %AppCount.Admins.Region{
          name: sequence(:name, &"Property#{&1} Region")
        }
      end

      def permission_factory do
        %AppCount.Admins.Permission{}
      end

      def scoping_factory do
        %AppCount.Properties.Scoping{}
      end

      def role_factory do
        %AppCount.Admins.Role{
          name: "Some Role",
          permissions: %{properties: :write}
        }
      end

      def profile_factory do
        %AppCount.Admins.Profile{
          admin: build(:admin)
        }
      end
    end
  end
end
