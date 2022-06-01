defmodule AppCount.Ledgers.ChargeCodeRepoTest do
  alias AppCount.Core.ClientSchema
  use AppCount.DataCase
  alias AppCount.Ledgers.ChargeCodeRepo
  @moduletag :charge_code_repo

  setup do
    account = insert(:account)
    code1 = insert(:charge_code, account: account, code: "code1", name: "First Code")
    code2 = insert(:charge_code, code: "code2", name: "Second Code")
    {:ok, code1: code1, code2: code2, account: account}
  end

  test "list", %{code1: code1, code2: code2, account: account} do
    result = ChargeCodeRepo.list(ClientSchema.new("dasmen"))
    first_code = Enum.find(result, &(&1.id == code1.id))
    second_code = Enum.find(result, &(&1.id == code2.id))
    assert first_code.account_name == account.name
    assert first_code.account_id == account.id
    assert first_code.code == code1.code
    assert first_code.name == code1.name
    assert second_code.name == code2.name
  end
end
