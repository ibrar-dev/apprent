defmodule AppCount.Yardi.ImportResidentsTest do
  use AppCount.DataCase
  alias AppCount.Yardi.ImportResidents
  alias AppCount.Tenants.TenancyRepo
  alias AppCount.Leasing.LeaseRepo
  alias AppCount.Core.ClientSchema
  @moduletag :yardi_leasing_import_residents

  setup do
    property = insert(:property, external_id: "2010")
    {:ok, property: property}
  end

  test "import_residents raises error with non-configured property" do
    msg = "No external ID found for property Test Property"

    assert_raise RuntimeError, msg, fn ->
      ImportResidents.perform(
        ClientSchema.new(
          "dasmen",
          insert(:property).id
        ),
        AppCount.Support.Yardi.FakeGateway
      )
    end
  end

  @tag :slow
  # test takes 1817.5ms
  test "import_residents adds brand new tenants", %{property: property} do
    unit = insert(:unit, property: property, number: "4350-117")
    # When
    ImportResidents.perform(
      ClientSchema.new(
        "dasmen",
        property.id
      ),
      AppCount.Support.Yardi.FakeGateway
    )

    new_tenancy =
      TenancyRepo.get_by(unit_id: unit.id)
      |> Repo.preload(:tenant)

    assert new_tenancy.external_id == "t0044164"
    assert new_tenancy.start_date == ~D[2021-02-17]
    assert new_tenancy.expected_move_in == ~D[2021-02-17]

    new_lease = LeaseRepo.get_by(customer_ledger_id: new_tenancy.customer_ledger_id)
    assert new_lease.start_date == ~D[2021-02-17]
    assert new_lease.end_date == ~D[2022-02-16]
  end

  @tag :slow
  test "import_residents adds tenancy to existing tenant (ie. unit transfer)", %{
    property: property
  } do
    unit = insert(:unit, property: property, number: "4350-117")
    tenant = insert(:tenant, external_id: "p0207292")
    # When
    ImportResidents.perform(
      ClientSchema.new(
        "dasmen",
        property.id
      ),
      AppCount.Support.Yardi.FakeGateway
    )

    new_tenancy = TenancyRepo.get_by(unit_id: unit.id, tenant_id: tenant.id)

    assert new_tenancy.external_id == "t0044164"
    assert new_tenancy.start_date == ~D[2021-02-17]
    assert new_tenancy.expected_move_in == ~D[2021-02-17]

    new_lease = LeaseRepo.get_by(customer_ledger_id: new_tenancy.customer_ledger_id)
    assert new_lease.start_date == ~D[2021-02-17]
    assert new_lease.end_date == ~D[2022-02-16]
  end

  @tag :slow
  test "import_residents updates tenancy for existing tenant", %{property: property} do
    unit = insert(:unit, property: property, number: "4350-117")
    tenant = insert(:tenant, external_id: "p0207292")
    tenancy = insert(:tenancy, tenant: tenant, unit: unit, external_id: "t0044164")
    # When
    ImportResidents.perform(
      ClientSchema.new(
        "dasmen",
        property.id
      ),
      AppCount.Support.Yardi.FakeGateway
    )

    updated_tenancy = TenancyRepo.get(tenancy.id)

    assert updated_tenancy.external_id == "t0044164"
    # In this case we do NOT want the start_date on the tenancy to change
    assert updated_tenancy.start_date == tenancy.start_date
    assert updated_tenancy.expected_move_in == ~D[2021-02-17]

    new_lease = LeaseRepo.get_by(customer_ledger_id: updated_tenancy.customer_ledger_id)
    assert new_lease.start_date == ~D[2021-02-17]
    assert new_lease.end_date == ~D[2022-02-16]
  end

  @tag :slow
  # test takes 1828.7ms
  test "import_residents updates tenancy for existing tenant and handles existing lease", %{
    property: property
  } do
    unit = insert(:unit, property: property, number: "4350-117")
    tenant = insert(:tenant, external_id: "p0207292")
    tenancy = insert(:tenancy, tenant: tenant, unit: unit, external_id: "t0044164")
    lease = insert(:leasing_lease, customer_ledger: tenancy.customer_ledger, unit: unit)
    # When
    ImportResidents.perform(
      ClientSchema.new(
        "dasmen",
        property.id
      ),
      AppCount.Support.Yardi.FakeGateway
    )

    updated_tenancy = TenancyRepo.get(tenancy.id)

    assert updated_tenancy.external_id == "t0044164"
    # In this case we do NOT want the start_date on the tenancy to change
    assert updated_tenancy.start_date == tenancy.start_date
    assert updated_tenancy.expected_move_in == ~D[2021-02-17]

    updated_lease = LeaseRepo.get(lease.id)
    assert updated_lease.start_date == ~D[2021-02-17]
    assert updated_lease.end_date == ~D[2022-02-16]
  end

  @tag :slow
  # this test takes 1871.8ms
  test "import_residents updates tenancy for existing tenant and handles multiple existing lease",
       %{property: property} do
    unit = insert(:unit, property: property, number: "4350-117")
    tenant = insert(:tenant, external_id: "p0207292")
    tenancy = insert(:tenancy, tenant: tenant, unit: unit, external_id: "t0044164")
    insert(:leasing_lease, customer_ledger: tenancy.customer_ledger, unit: unit)
    insert(:leasing_lease, customer_ledger: tenancy.customer_ledger, unit: unit)
    # When
    ImportResidents.perform(
      ClientSchema.new(
        "dasmen",
        property.id
      ),
      AppCount.Support.Yardi.FakeGateway
    )

    updated_tenancy = TenancyRepo.get(tenancy.id)

    assert updated_tenancy.external_id == "t0044164"
    # In this case we do NOT want the start_date on the tenancy to change
    assert updated_tenancy.start_date == tenancy.start_date
    assert updated_tenancy.expected_move_in == ~D[2021-02-17]

    [only_lease] =
      LeaseRepo.leases_by_customer_id(ClientSchema.new("dasmen", tenancy.customer_ledger_id))

    assert only_lease.start_date == ~D[2021-02-17]
    assert only_lease.end_date == ~D[2022-02-16]
  end

  @tag :slow
  # this test takes 1583.5ms
  # Why is this so slow?  it uses FakeGateway and not hitting the internet but is still crazy slow ??
  test "import_residents includes actual move out dates and does not create account for already moved-out tenants",
       %{property: property} do
    ImportResidents.perform(
      ClientSchema.new(
        "dasmen",
        property.id
      ),
      AppCount.Support.Yardi.FakeGateway
    )

    tenant = AppCount.Tenants.TenantRepo.get_by(external_id: "p0065487")
    tenancy = TenancyRepo.get_by(external_id: "t0019239", tenant_id: tenant.id)
    assert tenancy.expected_move_in == ~D[2015-07-01]
    assert tenancy.actual_move_out == ~D[2021-06-01]

    account = AppCount.Accounts.AccountRepo.get_by_tenant(tenant)

    refute account
  end

  @tag :slow
  # this test takes 1843.9ms
  test "import_residents includes actual move out dates and payment_accepted values", %{
    property: property
  } do
    tenant = insert(:tenant, external_id: "p0065487")
    account = insert(:user_account, tenant: tenant)

    ImportResidents.perform(
      ClientSchema.new(
        "dasmen",
        property.id
      ),
      AppCount.Support.Yardi.FakeGateway
    )

    tenancy = TenancyRepo.get_by(external_id: "t0019239", tenant_id: tenant.id)
    assert tenancy.expected_move_in == ~D[2015-07-01]
    assert tenancy.actual_move_out == ~D[2021-06-01]

    assert AppCount.Accounts.account_lock_exists?(ClientSchema.new("dasmen", account.id))
  end

  test "import_residents skips applicants", %{property: property} do
    ImportResidents.perform(
      ClientSchema.new(
        "dasmen",
        property.id
      ),
      AppCount.Support.Yardi.FakeGateway
    )

    refute TenancyRepo.get_by(external_id: "t0051796")
  end
end
