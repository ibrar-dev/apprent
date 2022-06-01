defmodule AppCount.Leasing.BlueMoon.CreateLeaseTest do
  use AppCount.DataCase
  alias AppCount.Leasing.BlueMoon.CreateLease
  alias AppCount.Support.HTTPClient
  alias AppCount.Core.ClientSchema

  setup do
    external_lease = insert(:bluemoon_external_lease)
    insert(:processor, property: external_lease.unit.property, name: "BlueMoon", type: "lease")
    {:ok, external_lease: external_lease}
  end

  test "create_lease with valid ExternalLease saves external ids", %{
    external_lease: external_lease
  } do
    AppCount.BlueMoonHelper.mock_bluemoon_responses(
      ["CreateLease", "CreateSessionIn", "ListForms", "ListCustomForms", "RequestEsignature"],
      :no_session
    )

    {:ok, updated_lease} = CreateLease.create(ClientSchema.new("dasmen", external_lease))
    assert updated_lease.external_id == "15151515"
    assert updated_lease.signature_id == "161616161"
    HTTPClient.stop()
  end
end
