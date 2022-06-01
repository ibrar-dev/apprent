defmodule AppCount.Ledgers.ChargesTest do
  use AppCount.DataCase
  import AppCount.Factory
  import AppCount.LeaseHelper
  alias AppCount.Ledgers.Utils.Charges
  alias AppCount.Ledgers.Charge
  alias AppCount.Repo
  alias AppCount.Core.ClientSchema

  setup do
    property = insert(:property)
    start = %Date{year: 2018, month: 1, day: 1}

    leases =
      Enum.map(
        ["A", "B", "C", "D"],
        fn letter ->
          insert_lease(%{
            start_date: start,
            end_date: Timex.shift(start, years: 1),
            unit: insert(:unit, property: property, number: "4302#{letter}")
          })
        end
      )

    ~M[ leases, property]
  end

  test "imports charges from CSV", %{leases: leases, property: property} do
    expected =
      [
        "4302A-17.70-Administration Fees Income",
        "4302A-23.59-Administration Fees Income",
        "4302A-6.14-Administration Fees Income",
        "4302B-4.79-Administration Fees Income",
        "4302B-6.37-Administration Fees Income",
        "4302B-6.14-Administration Fees Income",
        "4302C-14.96-Administration Fees Income",
        "4302C-19.94-Administration Fees Income",
        "4302C-6.14-Administration Fees Income",
        "4302D-7.09-Administration Fees Income",
        "4302D-9.46-Administration Fees Income"
      ]
      |> Enum.sort()

    upload = %Plug.Upload{
      content_type: "text/csv",
      filename: "utilities.csv",
      path: Path.expand("../../resources/utilities.csv", __DIR__)
    }

    Charges.import_csv(ClientSchema.new("dasmen", property.id), upload)

    result =
      Enum.flat_map(
        leases,
        fn lease ->
          Repo.preload(lease, bills: :charge_code).bills
          |> Enum.map(&"#{lease.unit.number}-#{&1.amount}-#{&1.charge_code.name}")
        end
      )
      |> Enum.sort()

    assert result == expected
  end

  test "update_charge", %{leases: leases} do
    charge = insert(:bill, lease: hd(leases))
    desc = "New Description"
    Charges.update_charge(charge.id, ClientSchema.new("dasmen", %{"description" => desc}))
    refute charge.description == desc
    assert Repo.get(Charge, charge.id).description == desc
  end

  test "admin cannot delete_charge", ~M[leases] do
    charge = insert(:bill, lease: hd(leases))
    client = AppCount.Public.get_client_by_schema("dasmen")

    Charges.delete_charge(
      ClientSchema.new(client.client_schema, %{roles: MapSet.new(["Admin"])}),
      charge.id
    )

    assert Repo.get(Charge, charge.id, prefix: client.client_schema)
  end

  test "super_admin can delete_charge", ~M[leases] do
    charge = insert(:bill, lease: hd(leases))
    super_admin = AppCount.UserHelper.new_admin(%{roles: ["Super Admin"]})
    client = AppCount.Public.get_client_by_schema("dasmen")

    super_admin = Repo.get!(AppCount.Admins.Admin, super_admin.id, prefix: client.client_schema)

    Charges.delete_charge(ClientSchema.new(client.client_schema, super_admin), charge.id)
    refute Repo.get(Charge, charge.id, prefix: client.client_schema)
  end
end
