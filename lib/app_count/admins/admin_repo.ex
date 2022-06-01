defmodule AppCount.Admins.AdminRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Admins.Admin,
    preloads: [permissions: [region: [scopings: [property: :setting]]], email_subscriptions: []]

  def get_by_uuid(uuid, client_schema) do
    Repo.get_by(@schema, [uuid: uuid], prefix: client_schema)
  end

  def get_by_id(id, client_schema) do
    Repo.get_by(@schema, [id: id], prefix: client_schema)
  end
end
