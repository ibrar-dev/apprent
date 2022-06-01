alias AppCount.Admins.Admin
alias AppCount.Repo
import Ecto.Query
alias AppCount.Core.ClientSchema

# Clear out super-admin user
Repo.delete_all(from(Admin, where: [email: "admin@example.com"]))

Repo.delete_all(
  from(AppCount.Public.User, where: [username: "admin@example.com"]),
  prefix: "public"
)

client = AppCount.Public.get_client_by_schema("dasmen")

{:ok, admin} =
  ClientSchema.new(
    client.client_schema,
    %{
      "email" => "imos@example.com",
      "password" => "password",
      "name" => "Dev Admin",
      "username" => "admin@example.com",
      "client_id" => client.id,
      "is_super_admin" => true,
      "permissions" => AppCount.Admins.Auth.Permissions.super_admin()
    }
  )
  |> AppCount.Admins.Utils.Admins.create_admin()

AppCount.Admins.Utils.Admins.update_admin(
  admin.id,
  ClientSchema.new(
    client.client_schema,
    %{
      roles: [
        "Accountant",
        "Admin",
        "Regional",
        "Super Admin",
        "Tech"
      ]
    }
  )
)

# TODO: should use AdminRepo to add permissions
Repo.all(from(x in AppCount.Admins.Region))
|> Enum.map(fn x -> x.id end)
|> Enum.map(fn id -> AppCount.Admins.attach_admin(id, admin.id) end)
