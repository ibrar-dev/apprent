defmodule AppCountWeb.API.AdminView do
  use AppCountWeb, :view
  use AppCountWeb.ChangesetView

  def render("index.json", %{admins: admins}) do
    render_many(admins, __MODULE__, "admin.json")
  end

  def render("admin.json", %{admin: admin}) do
    %{
      id: admin.id,
      username: admin.username,
      name: admin.name,
      email: admin.email,
      roles: admin.roles,
      entity_ids: admin.entity_ids,
      profile: admin.profile
    }
  end
end
