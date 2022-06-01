defmodule AppCount.Leasing.BlueMoon.PollForSignatures do
  alias AppCount.Leasing.ExternalLeaseRepo
  alias AppCount.Leasing.Utils.ExternalLeases
  alias AppCount.Core.ClientSchema

  def poll(%ClientSchema{} = schema) do
    schema
    |> ExternalLeaseRepo.get_all_pending_leases()
    |> Enum.filter(&(ExternalLeases.get_status(&1) == "Signature Requested"))
    |> Enum.each(&check_signed/1)
  end

  def check_signed(%AppCount.Leasing.ExternalLease{} = lease) do
    credentials = ExternalLeases.credentials_for(lease)

    with {:ok, status} <- BlueMoon.get_signature_status(credentials, lease.signature_id),
         {:ok, updated} <- update_signators(lease, status) do
      if ExternalLeases.get_status(updated) == "Signed" do
        AppCount.Leasing.BlueMoon.Execute.execute(updated, credentials)
      else
        updated
      end
    else
      e -> e
    end
  end

  defp update_signators(%AppCount.Leasing.ExternalLease{} = lease, status) do
    signators = Enum.into(status, %{}, fn %{name: n, date_signed: d} -> {n, d} end)

    ExternalLeaseRepo.update(lease, %{signators: Map.merge(lease.signators, signators)},
      prefix: lease.__meta__.prefix
    )
  end
end
