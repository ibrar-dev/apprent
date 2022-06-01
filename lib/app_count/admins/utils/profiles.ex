defmodule AppCount.Admins.Utils.Profiles do
  alias AppCount.Repo
  alias AppCount.Admins.Profile
  alias AppCount.Core.ClientSchema

  def create_profile(%AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: params
      }) do
    %Profile{}
    |> Profile.changeset(params)
    |> Repo.insert(prefix: client_schema)
  end

  def update_profile(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: id
        },
        params
      ) do
    Repo.get(Profile, id, prefix: client_schema)
    |> Profile.changeset(params)
    |> Repo.update(prefix: client_schema)
  end

  def delete_profile(admin, %AppCount.Core.ClientSchema{
        name: client_schema,
        attrs: id
      }) do
    Repo.get(Profile, id, prefix: client_schema)
    |> AppCount.Admins.Utils.Actions.admin_delete(ClientSchema.new(client_schema, admin))
  end
end
