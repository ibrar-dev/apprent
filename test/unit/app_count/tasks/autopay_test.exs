defmodule AppCount.AutopayTaskTest do
  use AppCount.DataCase
  use AppCount.Decimal
  alias AppCount.Leases.ExternalLedgerBoundary
  alias AppCount.Accounts.ProcessAutopay, as: Subject
  alias AppCount.Accounts
  @moduletag :autopay_task

  # This module is not tested that well.
  # Issues that I ran into:
  #  Cannot use PropBuilder to add a payment source and cannot add autopay without a payment source
  #  Have to use factories but then no real way to test that payment went through using RentSaga
  # To truly test this page:
  ## Add payment_source to PropBuilder
  ## Add external_balance to PropBuilder

  def add_external_balance(external_id, payment_amount \\ 3, charge_amount \\ 5) do
    yardi_payment = %Yardi.Response.GetResidentData.Payment{amount: payment_amount}
    yardi_charge = %Yardi.Response.GetResidentData.Charge{amount: charge_amount}
    entry_array = [yardi_payment, yardi_charge]
    ExternalLedgerBoundary.save_balance(entry_array, external_id)
  end

  setup do
    tenant = insert(:tenant, external_id: "1234")
    tenancy = insert(:tenancy, tenant: tenant, external_id: "1234")

    # lease = insert_lease(%{start_date: @start_date, end_date: @end_date, charges: @charges, tenants: [tenant]})
    account = insert(:user_account, tenant: tenant)
    autopay = insert(:autopay, account: account)
    # tenant = hd(lease.tenants)

    ~M[autopay, account, tenant, tenancy]
  end

  @tag :slow
  test "task does not pay if autopay is not active", ~M[autopay, tenant] do
    params = %{
      tenant_id: tenant.id,
      active: true
    }

    Accounts.inactive_autopay(autopay.id, params)

    result = Subject.get_list_of_autopays("dasmen")

    assert length(result) == 0
  end

  @tag :slow
  test "check_if_balance returns nil if no balance" do
    [autopay] = Subject.get_list_of_autopays("dasmen")

    payment_pre_count = Repo.count(AppCount.Ledgers.Payment)

    res =
      autopay
      |> Subject.check_if_balance()

    assert is_nil(res)

    payment_post_count = Repo.count(AppCount.Ledgers.Payment)

    assert payment_pre_count == payment_post_count
  end

  @tag :slow
  test "still no payment run if balance exceeds $3000", ~M[tenant] do
    add_external_balance(tenant.external_id, 0, 3001)

    payment_pre_count = Repo.count(AppCount.Ledgers.Payment)

    [autopay] = Subject.get_list_of_autopays("dasmen")

    res =
      autopay
      |> Subject.check_if_balance()

    assert is_nil(res)

    payment_post_count = Repo.count(AppCount.Ledgers.Payment)

    assert payment_pre_count == payment_post_count
  end

  # Balance comes in as a dollar value, needs to be converted to cents
  @tag :slow
  test "convert_to_cents returns correct amount" do
    res = Subject.convert_to_cents(65.87)

    assert res == 6587
  end
end
