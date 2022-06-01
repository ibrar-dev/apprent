defmodule AppCount.Accounting.AccountsTest do
  use AppCount.DataCase
  alias AppCount.Accounting
  alias AppCount.Repo
  alias AppCount.Accounting.Account
  alias AppCount.Core.ClientSchema
  @moduletag :accounting_accounts

  setup do
    admin = AppCount.UserHelper.new_admin()

    account = insert(:account)
    ~M[admin, account]
  end

  test "list_accounts select returns the expected_fields" do
    result = Accounting.list_accounts(ClientSchema.new("dasmen"))

    expected_fields = [
      :id,
      :name,
      :is_credit,
      :is_balance,
      :is_cash,
      :is_payable,
      :num,
      :total_account,
      :description,
      :external_id
    ]

    diff =
      hd(result)
      |> Map.keys()
      |> MapSet.new()
      |> MapSet.difference(MapSet.new(expected_fields))

    assert Enum.empty?(diff)
  end

  test "update_account", ~M[ account] do
    {:ok, %Account{} = result} =
      Accounting.update_account(account.id, ClientSchema.new("dasmen", %{name: "Unused Account"}))

    assert result.name == "Unused Account"
  end

  test "delete_account", ~M[admin, account] do
    client = AppCount.Public.get_client_by_schema("dasmen")

    {:ok, %Account{}} =
      Accounting.delete_account(ClientSchema.new(client.client_schema, admin), account.id)

    refute Repo.get(Account, account.id)
  end
end
