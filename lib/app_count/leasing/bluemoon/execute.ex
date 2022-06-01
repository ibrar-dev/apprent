defmodule AppCount.Leasing.BlueMoon.Execute do
  alias AppCount.Leasing.ExternalLease
  alias AppCount.Leasing.Utils.ExternalLeases

  def execute(lease, credentials \\ nil)

  def execute(%ExternalLease{admin: %{id: _}} = lease, credentials) do
    credentials = credentials || ExternalLeases.credentials_for(lease)

    case BlueMoon.execute_lease(credentials, lease.signature_id, lease.admin.name) do
      {:ok, "true"} ->
        AppCount.Leasing.ExternalLeaseRepo.update(lease, %{executed: true},
          prefix: lease.__meta__.prefix
        )

      e ->
        e
    end
  end

  def execute(%ExternalLease{} = lease, credentials) do
    AppCount.Repo.preload(lease, [:admin], prefix: lease.__meta__.prefix)
    |> execute(credentials)
  end
end
