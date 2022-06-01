defmodule AppCount.Yardi.ImportAccountsCase do
  use AppCount.DataCase
  alias AppCount.Yardi.ImportAccounts

  @moduletag :yardi_import_accounts

  @tag :slow
  test "imports chart of accounts" do
    property = insert(:property, external_id: "1234")
    insert(:processor, property: property, type: "management", name: "Yardi")

    # When
    ImportAccounts.perform(property.id, AppCount.Support.Yardi.FakeGateway)

    # Then
    assert Repo.get_by(AppCount.Accounting.Account, name: "Bad Debt Recovery", num: 41_330_000)
  end
end
