defmodule AppCount.Leasing.BlueMoon.PollForSignaturesTest do
  use AppCount.DataCase
  alias AppCount.Leasing.BlueMoon.PollForSignatures
  alias AppCount.Support.HTTPClient
  alias AppCount.Core.ClientSchema

  setup do
    lease = insert(:bluemoon_external_lease)
    insert(:processor, property: lease.unit.property, name: "BlueMoon", type: "lease")
    {:ok, external_lease: lease}
  end

  test "retrieves signators from BlueMoon", %{external_lease: lease} do
    AppCount.BlueMoonHelper.mock_bluemoon_responses(["GetEsignatureData", "ExecuteLease"])
    PollForSignatures.poll(ClientSchema.new("dasmen"))
    HTTPClient.stop()
    reloaded = Repo.get(AppCount.Leasing.ExternalLease, lease.id)
    assert reloaded.signators == %{"Joe Tenant" => "09/26/2019 23:53:36"}
    assert reloaded.executed
  end

  test "incomplete signators does not execute", %{external_lease: lease} do
    signators = %{"Joe Tenant" => nil, "Someone Else" => nil}
    AppCount.Leasing.ExternalLeaseRepo.update(lease, %{signators: signators})
    AppCount.BlueMoonHelper.mock_bluemoon_responses(["GetEsignatureData", "ExecuteLease"])
    PollForSignatures.poll(ClientSchema.new("dasmen"))
    HTTPClient.stop()
    reloaded = Repo.get(AppCount.Leasing.ExternalLease, lease.id, prefix: "dasmen")
    assert reloaded.signators == %{"Joe Tenant" => "09/26/2019 23:53:36", "Someone Else" => nil}
    refute reloaded.executed
  end
end
