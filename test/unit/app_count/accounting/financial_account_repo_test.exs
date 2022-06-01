defmodule AppCount.Accounting.AccountRepoTest do
  use AppCount.DataCase
  alias AppCount.Accounting.AccountRepo

  describe "insert/1" do
    test "regular" do
      original_count = AccountRepo.count()
      account_params = %{name: UUID.uuid4()}

      # When
      {:ok, result} = AccountRepo.insert(account_params)

      assert result
      actual_count = AccountRepo.count()
      assert actual_count == original_count + 1
    end
  end

  describe "update/2" do
    setup do
      expected_description = "A very good account"
      account_params = %{name: UUID.uuid4()}
      {:ok, account} = AccountRepo.insert(account_params)

      ~M[account, expected_description]
    end

    test "regular", ~M[account, expected_description] do
      # Given
      update_params = %{description: expected_description}
      original_count = AccountRepo.count()

      # When
      {:ok, result} = AccountRepo.update(account, update_params)

      # Then
      assert result.description == expected_description
      actual_count = AccountRepo.count()
      assert actual_count == original_count
    end
  end
end
