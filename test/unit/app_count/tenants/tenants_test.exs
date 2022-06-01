defmodule AppCount.Tenants.TenantsTest do
  use AppCount.DataCase
  alias AppCount.Tenants
  use Bamboo.Test, shared: true
  @moduletag :tenants

  setup do
    unit = insert(:unit)

    rent_account =
      AppCount.Repo.get_by(AppCount.Accounting.Account, name: "Rent") ||
        insert(:account, name: "Rent")

    tenant = insert(:tenant, email: "anemail@somewhere.net")
    now = AppCount.current_date()

    tenancy =
      insert(
        :tenancy,
        start_date: Timex.shift(now, years: -2),
        tenant: tenant,
        unit: unit
      )

    {:ok, [unit: unit, rent_account: rent_account, tenant: tenant, tenancy: tenancy]}
  end

  test "create_tenant function works", context do
    today = AppCount.current_date()
    cc_id = AppCount.Accounting.SpecialAccounts.get_charge_code(:rent).id

    params = %{
      persons: [
        %{
          first_name: "Big",
          last_name: "Bird",
          status: "Lease Holder"
        }
      ],
      start_date: today,
      end_date: Timex.shift(today, years: 1),
      unit_id: context.unit.id,
      charges: [%{"amount" => 800, "charge_code_id" => cc_id}]
    }

    {:ok, result} = Tenants.create_tenant(params)
    tenant = hd(result.tenants)
    assert tenant.first_name == "Big"
    assert tenant.last_name == "Bird"
    assert hd(result.occupancies).tenant_id == tenant.id
    assert result.lease.start_date == today
  end

  test "create_concessions function works", context do
    today = AppCount.current_date()
    response = %{auth_code: "784550", account_number: "XXXX3233"}
    application = insert(:rent_application)

    payment =
      insert(
        :payment,
        amount: 25,
        transaction_id: "12345678",
        source: "web",
        response: response,
        post_month: "2019-07-01",
        property: insert(:property),
        application_id: application.id
      )

    person = insert(:rent_apply_person, application: application)
    name = String.split(person.full_name, " ")
    cc_id = AppCount.Accounting.SpecialAccounts.get_charge_code(:rent).id

    params = %{
      persons: [
        %{
          first_name: List.first(name),
          last_name: List.last(name),
          status: "Lease Holder"
        }
      ],
      start_date: today,
      end_date: Timex.shift(today, years: 1),
      unit_id: context.unit.id,
      payment_id: payment,
      charges: [%{"amount" => 800, "charge_code_id" => cc_id}]
    }

    {:ok, result} = Tenants.create_tenant(params, %{application_id: application.id})
    tenant = hd(result.tenants)
    assert tenant.first_name == List.first(name)
    assert tenant.last_name == List.last(name)
    assert tenant.application_id == application.id
    assert hd(result.occupancies).tenant_id == tenant.id
    assert result.lease.start_date == today
  end

  test "create_new_tenant function works", context do
    today = AppCount.current_date()
    cc_id = AppCount.Accounting.SpecialAccounts.get_charge_code(:rent).id

    params = %{
      first_name: "Happy",
      last_name: "Bird",
      start_date: today,
      end_date: Timex.shift(today, years: 1),
      unit_id: context.unit.id,
      charges: [%{"amount" => 800, "charge_code_id" => cc_id}]
    }

    {:ok, res} = Tenants.create_new_tenant(params)
    create_tenant = res.create_tenant
    tenant = create_tenant.tenant
    occupancy = create_tenant.occupancy
    lease = res.lease
    assert tenant.first_name == "Happy"
    assert tenant.last_name == "Bird"
    assert occupancy.tenant_id == tenant.id
    assert occupancy.lease_id == lease.id
    assert lease.start_date == today
  end

  test "create_tenant throws error when invalid", context do
    today = AppCount.current_date()

    params = %{
      start_date: nil,
      end_date: Timex.shift(today, years: 1),
      unit_id: context.unit.id,
      rent: 800
    }

    {:error, :lease, result, _} = Tenants.create_tenant(params)
    assert result.errors[:start_date]
  end

  test "send_individual_email", %{tenant: tenant} do
    %{
      "body" => "Here is an email body",
      "subject" => "Here is an email subject",
      "tenant_id" => tenant.id,
      "attachments" => []
    }
    |> Tenants.send_individual_email()

    assert_email_delivered_with(
      subject: "[AppRent] Here is an email subject",
      html_body: ~r/Here is an email body/,
      to: [
        nil: "anemail@somewhere.net"
      ]
    )
  end

  test "list_tenants_balance", %{tenant: tenant, tenancy: tenancy} do
    ledger = tenancy.customer_ledger
    insert(:bill, customer_ledger: ledger, amount: 250)
    insert(:bill, customer_ledger: ledger, amount: 300)
    insert(:bill, customer_ledger: ledger, amount: -50)
    insert(:payment, customer_ledger: ledger, tenant: tenant, amount: 250)
    insert(:payment, customer_ledger: ledger, tenant: tenant, amount: 200)

    result =
      ledger.property_id
      |> Tenants.list_tenants_balance()
      |> hd

    assert Decimal.to_float(result.balance) == 50
    assert result.first_name == tenant.first_name
  end

  test "tenant_search", %{unit: unit, tenant: tenant} do
    result =
      %AppCountAuth.Users.Admin{property_ids: [unit.property_id]}
      |> Tenants.tenant_search(tenant.first_name, unit.property_id)
      |> hd

    assert result.id == tenant.id
  end
end
