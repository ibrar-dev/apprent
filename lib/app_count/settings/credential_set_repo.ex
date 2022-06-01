defmodule AppCount.Settings.CredentialSetRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Settings.CredentialSet

  def list() do
    Repo.all(@schema)
  end
end
