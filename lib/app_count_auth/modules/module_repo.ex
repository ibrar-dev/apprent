defmodule AppCountAuth.ModuleRepo do
  use AppCount.Core.GenericRepo, schema: AppCountAuth.Module

  def list() do
    Repo.all(@schema, prefix: "public")
  end
end
