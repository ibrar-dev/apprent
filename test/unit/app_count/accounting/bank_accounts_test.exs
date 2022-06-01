defmodule AppCount.Accounting.BankAccountsTest do
  use AppCount.DataCase
  alias AppCount.Accounting
  alias AppCount.Repo
  alias AppCount.Accounting.BankAccount
  alias AppCount.Core.ClientSchema

  setup do
    {:ok, bank_account: insert(:bank_account)}
  end

  test "list_bank_accounts", %{bank_account: bank_account} do
    result = Accounting.list_bank_accounts()
    assert length(result) == 1
    assert hd(result).id == bank_account.id
  end

  test "create_bank_account" do
    {:ok, result} =
      Accounting.create_bank_account(%{
        "name" => "Some Body",
        "bank_name" => "Wells Fakeout",
        "routing_number" => "956325",
        "account_number" => "92567252452",
        "account_id" => insert(:account).id,
        "property_ids" => [insert(:property).id, insert(:property).id]
      })

    assert result.name == "Some Body"
    assert result.bank_name == "Wells Fakeout"
  end

  test "update_bank_account", %{bank_account: bank_account} do
    {:ok, %BankAccount{} = result} =
      Accounting.update_bank_account(
        bank_account.id,
        %{
          "name" => "Some Body Else"
        }
      )

    assert result.name == "Some Body Else"
  end

  test "delete_bank_account", %{bank_account: bank_account} do
    admin = AppCount.UserHelper.new_admin()
    client = AppCount.Public.get_client_by_schema("dasmen")

    Accounting.delete_bank_account(ClientSchema.new(client.client_schema, admin), bank_account.id)
    refute Repo.get(BankAccount, bank_account.id, prefix: client.client_schema)
  end

  test "get_bank_account", %{bank_account: bank_account} do
    assert Accounting.get_bank_account(bank_account.id)
  end
end
