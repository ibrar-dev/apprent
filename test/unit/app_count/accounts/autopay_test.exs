defmodule AppCount.Accounts.AutopayTest do
  use AppCount.DataCase
  alias AppCount.Accounts
  alias AppCount.Accounts.Autopay

  setup do
    account =
      insert(:user_account)
      |> AppCount.UserHelper.new_account()

    payment_source = insert(:payment_source)

    ~M[account, payment_source]
  end

  # packing these tests together reduces the run time from 6.2 seconds to 0.7 seconds
  test "autopay", ~M[account, payment_source ] do
    tenant_id = account.tenant_id

    params = %{
      account_id: account.id,
      payment_source_id: payment_source.id,
      active: true,
      tenant_id: tenant_id,
      agreement_text: ""
    }

    # When create
    Accounts.create_autopay(params)

    # Then
    autopay = Repo.get_by(Autopay, account_id: account.id)
    assert autopay.active == true

    # When Update
    Accounts.update_autopay(autopay.id, %{
      params
      | agreement_text: "this is the new agreement text"
    })

    # Then
    autopay = Repo.get(Autopay, autopay.id)
    assert autopay.agreement_text == "this is the new agreement text"

    # When inactive autopay
    Accounts.inactive_autopay(autopay.id, params)

    assert_receive %AppCount.Core.DomainEvent{
      content: %{changes: %{active: false}},
      name: "changed",
      source: AppCount.Accounts.Utils.Autopays,
      subject_name: "AppCount.Tenants.Tenant",
      subject_id: ^tenant_id,
      topic: "tenants__tenants"
    }

    # Then
    autopay = Repo.get(Autopay, autopay.id)
    refute autopay.active

    # When activate
    Accounts.activate_autopay(autopay.id, params)

    # Then
    autopay = Repo.get(Autopay, autopay.id)
    assert autopay.active

    assert_receive %AppCount.Core.DomainEvent{
      content: %{changes: %{active: true}},
      name: "changed",
      source: AppCount.Accounts.Utils.Autopays,
      subject_name: "AppCount.Tenants.Tenant",
      subject_id: ^tenant_id,
      topic: "tenants__tenants"
    }
  end
end
