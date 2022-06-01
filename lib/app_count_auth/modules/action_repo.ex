defmodule AppCountAuth.ActionRepo do
  use AppCount.Core.GenericRepo, schema: AppCountAuth.Action

  def list() do
    @schema
    |> order_by([action], asc: action.description)
    |> Repo.all(prefix: "public")
    |> Repo.preload(:module, prefix: "public")
  end

  def list(module_id) do
    from(action in @schema,
      where: action.module_id == ^module_id,
      order_by: [asc: action.description]
    )
    |> Repo.all(prefix: "public")
    |> Repo.preload(:module, prefix: "public")
  end
end
