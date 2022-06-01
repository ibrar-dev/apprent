defmodule AppCount.Finance.FinanceBoundaryTest do
  use AppCount.Case
  alias AppCount.Finance.FinanceBoundary

  defmodule AccountRepoParrot do
    use TestParrot

    parrot(:repo, :all, [])

    parrot(:repo, :insert, {
      :ok,
      %AppCount.Finance.Account{
        name: "Some Account",
        number: "12345678",
        natural_balance: "credit",
        type: "Asset",
        description: "This is an account",
        id: 123
      }
    })

    parrot(:repo, :get_aggregate, %AppCount.Finance.Account{
      name: "Some Account",
      number: "12345678",
      natural_balance: "credit",
      type: "Asset",
      description: "This is an account",
      id: 123
    })
  end

  describe "list_accounts/0" do
    test "succeeds" do
      # When
      {:ok, _accounts} = FinanceBoundary.list_accounts(AccountRepoParrot)

      assert_receive :all
    end
  end

  describe "create_account/1" do
    test "succeeds" do
      params = %{
        name: "Some Account",
        number: "12345678",
        natural_balance: "credit",
        type: "Asset",
        description: "This is an account"
      }

      # When
      {:ok, result} = FinanceBoundary.create_account(params, AccountRepoParrot)

      assert %AppCount.Finance.Account{} = result

      assert_receive {:insert, _stuff}
    end
  end

  describe "get_account/1" do
    test "succeeds" do
      # When
      {:ok, _result} = FinanceBoundary.get_account(123, AccountRepoParrot)

      assert_receive {:get_aggregate, 123}
    end
  end
end
