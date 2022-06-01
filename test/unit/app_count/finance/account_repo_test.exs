defmodule AppCount.Finance.AccountRepoTest do
  use AppCount.DataCase
  alias AppCount.Finance.AccountRepo
  alias AppCount.Core.DomainEvent
  alias AppCount.Core.FinanceAccountTopic
  #  alias AppCount.Finance.Account

  setup do
    random_num = Enum.random(10_000_000..99_999_999)

    account_params = %{
      name: UUID.uuid4(),
      number: "#{random_num}",
      natural_balance: "credit",
      type: "Asset",
      subtype: "Fixed Asset"
    }

    ~M[account_params]
  end

  describe "insert/1" do
    test "regular", ~M[account_params] do
      original_count = AccountRepo.count()

      # When
      {:ok, result} = AccountRepo.insert(account_params)

      assert result
      actual_count = AccountRepo.count()
      assert actual_count == original_count + 1
    end

    test "publishes event", ~M[account_params] do
      FinanceAccountTopic.subscribe()

      # When
      {:ok, account} = AccountRepo.insert(account_params)

      assert_receive %DomainEvent{
        topic: "finance__accounts",
        name: "created",
        content: %{},
        subject_name: AppCount.Finance.Account,
        subject_id: subject_id,
        source: AppCount.Finance.AccountRepo
      }

      assert subject_id == account.id
    end
  end

  describe "update/2" do
    setup(%{account_params: account_params}) do
      expected_description = "A very good account"

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

    test "publishes event", ~M[account, expected_description] do
      update_params = %{description: expected_description}

      FinanceAccountTopic.subscribe()

      # When
      {:ok, account} = AccountRepo.update(account, update_params)

      assert_receive %DomainEvent{
        topic: "finance__accounts",
        name: "changed",
        content: %{},
        subject_name: AppCount.Finance.Account,
        subject_id: subject_id,
        source: AppCount.Finance.AccountRepo
      }

      assert subject_id == account.id
    end
  end
end
