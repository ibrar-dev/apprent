defmodule AppCount.Ledgers.BatchesTest do
  use AppCount.DataCase
  import AppCount.{Factory, LeaseHelper}
  @moduletag :accounting_batches

  setup do
    batch = insert(:batch)
    start = %Date{year: 2018, day: 1, month: 1}
    end_date = %Date{year: 2019, day: 1, month: 1}
    charges = [Rent: 500, Pet: 10, Something: 15]
    unit = insert(:unit, property: batch.property)
    lease = insert_lease(%{start_date: start, end_date: end_date, charges: charges, unit: unit})

    insert(:payment, property: batch.property, batch_id: batch.id, tenant_id: hd(lease.tenants).id)

    {:ok, batch: batch}
  end

  # TODO TEST THIS.
end
