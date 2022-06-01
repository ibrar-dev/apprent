defmodule AppCount.Leasing.RenewalPeriodsTest do
  use AppCount.DataCase
  alias AppCount.Leasing.Utils.RenewalPeriods
  alias AppCount.Leasing.RenewalPeriod
  alias AppCount.Core.ClientSchema

  @moduletag :leases_renewal_periods

  setup do
    property = insert(:property)
    admin = admin_with_access([property.id], roles: ["Regional"])
    {:ok, property: property, admin: Repo.get(AppCount.Admins.Admin, admin.id)}
  end

  test "renewal period CRUD", %{property: property} do
    params = %{
      "property_id" => property.id,
      "creator" => "Admin Admin",
      "start_date" => "2021-01-01",
      "end_date" => "2021-12-01",
      "packages" => [%{"min" => 1, "max" => 10, "amount" => 1200}]
    }

    {:ok, period} = RenewalPeriods.create_renewal_period(ClientSchema.new("dasmen", params))
    preloaded = Repo.preload(period, :packages)
    assert hd(preloaded.packages).max == 10

    RenewalPeriods.update_renewal_period(
      ClientSchema.new("dasmen", period.id),
      %{
        "start_date" => "2021-02-01",
        "packages" => []
      }
    )

    period =
      Repo.get(RenewalPeriod, period.id)
      |> Repo.preload(:packages)

    assert period.start_date == ~D[2021-02-01]
    assert period.packages == []
    RenewalPeriods.delete_renewal_period(ClientSchema.new("dasmen", period.id))
    refute Repo.get(RenewalPeriod, period.id)
  end

  test "notify_regional", %{property: property, admin: admin} do
    period = insert(:renewal_period, property: property)
    assert {:ok, nil} == RenewalPeriods.notify_regional(admin, period.id)
  end

  test "approve_renewal_period", %{property: property, admin: admin} do
    period = insert(:renewal_period, property: property)
    RenewalPeriods.approve_renewal_period(ClientSchema.new("dasmen", admin), period.id)
    reloaded = Repo.get(RenewalPeriod, period.id)
    assert reloaded.approval_admin == admin.name
  end

  test "notify_pm_renewal", %{property: property} do
    %{lease: lease, tenancies: [tenancy]} =
      AppCount.LeasingHelper.insert_lease(%{property: property})

    client = AppCount.Public.get_client_by_schema("dasmen")

    package_id = insert(:custom_package, lease: lease).renewal_package.id

    RenewalPeriods.notify_pm_renewal(
      ClientSchema.new(
        client.client_schema,
        lease.id
      ),
      tenancy.tenant_id,
      package_id
    )
  end

  test "print_period_letters", %{property: property} do
    doc_name = "#{property.id}_%_Renewal_Offer"
    path = Path.expand("../../../resources", __DIR__)

    pdfs =
      ["/Sample1.pdf", "/Sample2.pdf", "/Samples.pdf"]
      |> Enum.map(&File.read!(path <> &1))

    insert(:tenant_document, name: doc_name)
    insert(:tenant_document, name: doc_name)
    insert(:tenant_document, name: doc_name)
    AppCount.Support.HTTPClient.initialize(pdfs)
    result = RenewalPeriods.print_period_letters(property.id)
    AppCount.Support.HTTPClient.stop()
    assert is_binary(result)
    assert AppCount.Data.file_type(result) == :pdf
  end

  test "find_lease_packages", %{property: property, admin: admin} do
    %{lease: lease} =
      AppCount.LeasingHelper.insert_lease(%{
        property: property,
        charges: [
          Rent: 1000
        ]
      })

    result =
      RenewalPeriods.find_lease_packages(
        ClientSchema.new(admin.__meta__.prefix, admin),
        property.id,
        lease.id
      )

    assert result.id == lease.id
  end

  test "check_if_valid_period", %{property: property} do
    period = insert(:renewal_period, property: property)

    AppCount.LeasingHelper.insert_lease(%{
      property: property,
      start_date: period.start_date,
      end_date: Timex.shift(period.end_date, days: 2)
    })

    valid =
      RenewalPeriods.check_if_valid_period(
        ClientSchema.new("dasmen", property.id),
        Timex.shift(period.end_date, days: 1),
        Timex.shift(period.end_date, days: 100)
      )

    assert valid.valid == true
    assert valid.leases == 1

    invalid =
      RenewalPeriods.check_if_valid_period(
        ClientSchema.new("dasmen", property.id),
        Timex.shift(period.start_date, days: 1),
        Timex.shift(period.end_date, days: 1)
      )

    assert invalid.valid == false
    assert invalid.leases == 0
  end

  test "add_note", %{admin: admin} do
    period = insert(:renewal_period)
    RenewalPeriods.add_note(ClientSchema.new("dasmen", period.id), "Special Thing", admin)
    [note] = Repo.get(RenewalPeriod, period.id, prefix: "dasmen").notes
    assert note["text"] == "Special Thing"
    assert note["admin"] == admin.name
  end
end
