defmodule AppCount.Leasing.Utils.ExternalLeases do
  alias AppCount.Leasing.ExternalLease
  alias AppCount.Core.ClientSchema

  def get_status(%ExternalLease{} = lease) do
    cond do
      lease.executed -> "Executed"
      is_signed?(lease) -> "Signed"
      lease.signature_id -> "Signature Requested"
      lease.lease_id -> "Lease Created"
      true -> "Not Submitted"
    end
  end

  def is_signed?(%ExternalLease{signators: signators}) do
    map_size(signators) > 0 && Enum.all?(signators, fn {_signator, signed} -> !!signed end)
  end

  def credentials_for(%ExternalLease{} = lease) do
    property_id =
      AppCount.Properties.UnitRepo.get(lease.unit_id, prefix: lease.__meta__.prefix)
      |> Map.get(:property_id)

    ClientSchema.new(lease.__meta__.prefix, property_id)
    |> AppCount.Properties.Processors.processor_credentials("lease")
    |> wrap_credentials(lease.provider)
  end

  defp wrap_credentials(credentials, "BlueMoon") do
    struct(BlueMoon.Credentials, credentials)
  end
end
