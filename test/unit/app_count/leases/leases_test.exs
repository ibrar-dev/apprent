defmodule AppCount.Leases.LeasesTest do
  use AppCount.DataCase
  alias AppCount.Leases
  alias AppCount.Core.ClientSchema
  @moduletag :leases_leases

  setup do
    {:ok, lease: insert(:lease)}
  end

  test "update_leases", %{lease: lease} do
    today = AppCount.current_date()
    new_lease = insert(:lease)

    Leases.update_leases(
      [lease.id, new_lease.id],
      ClientSchema.new("dasmen", %{"expected_move_in" => today})
    )

    [lease.id, new_lease.id]
    |> Enum.each(fn lease_id ->
      assert Repo.get(Leases.Lease, lease_id).expected_move_in == today
    end)
  end

  test "document_url", %{lease: lease} do
    assert is_nil(Leases.document_url(lease.id))

    Leases.update_lease(
      lease.id,
      ClientSchema.new("dasmen", %{"document_id" => insert(:upload).id})
    )

    assert is_binary(Leases.document_url(lease.id))
  end
end
