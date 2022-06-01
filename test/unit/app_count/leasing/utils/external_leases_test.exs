defmodule AppCount.Leasing.Utils.ExternalLeasesCase do
  use AppCount.DataCase
  alias AppCount.Leasing.ExternalLease
  alias AppCount.Leasing.Utils.ExternalLeases

  test "get_status" do
    assert ExternalLeases.get_status(%ExternalLease{executed: true}) == "Executed"
    signators = %{"Harry Truman" => ~D[2021-01-01], "Barry Truman" => ~D[2021-01-04]}
    assert ExternalLeases.get_status(%ExternalLease{signators: signators}) == "Signed"
    signators = %{"Alexander T. Great" => nil}

    assert ExternalLeases.get_status(%ExternalLease{signators: signators, signature_id: "1234567"}) ==
             "Signature Requested"

    assert ExternalLeases.get_status(%ExternalLease{signators: signators, lease_id: "1234567"}) ==
             "Lease Created"

    assert ExternalLeases.get_status(%ExternalLease{signators: signators}) == "Not Submitted"
  end
end
