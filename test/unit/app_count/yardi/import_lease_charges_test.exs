defmodule AppCount.Yardi.ImportLeaseChargesCase do
  use AppCount.DataCase
  import AppCount.LeaseHelper
  alias AppCount.Yardi.ImportLeaseCharges
  @moduletag :yardi_import_lease_charges

  setup do
    property = insert(:property, external_id: "1234")
    tenant = insert(:tenant, external_id: "t4312")
    lease = insert_lease(%{tenants: [tenant], property: property})
    rent_cc = insert(:charge_code, code: "rent")
    mtm_cc = insert(:charge_code, code: "mtm")
    {:ok, property: property, tenant: tenant, lease: lease, rent_cc: rent_cc, mtm_cc: mtm_cc}
  end

  test "import", %{
    property: property,
    tenant: tenant,
    rent_cc: rent_cc,
    mtm_cc: mtm_cc
  } do
    insert(:processor, property: property, type: "management", name: "Yardi")
    {:ok, charges} = ImportLeaseCharges.import(tenant.id, AppCount.Support.Yardi.FakeGateway)

    expected = [
      %{
        amount: "900.00",
        charge_code_id: rent_cc.id,
        from_date: "2018-09-01",
        to_date: "2019-08-31"
      },
      %{
        amount: "1089.00",
        charge_code_id: rent_cc.id,
        from_date: "2019-09-01",
        to_date: "2019-08-31"
      },
      %{
        amount: "250.00",
        charge_code_id: mtm_cc.id,
        from_date: "2019-09-01",
        to_date: "2019-08-31"
      },
      %{
        amount: "1025.00",
        charge_code_id: rent_cc.id,
        from_date: "2019-09-01",
        to_date: "2020-08-31"
      },
      %{
        amount: "1050.00",
        charge_code_id: rent_cc.id,
        from_date: "2020-09-01",
        to_date: nil
      }
    ]

    assert charges == expected
  end
end
