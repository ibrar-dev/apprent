defmodule AppCount.Accounts.RentSagaRepoTest do
  use AppCount.DataCase
  alias AppCount.Accounts.RentSagaRepo
  alias AppCount.Support.AccountBuilder
  alias AppCount.Core.ClientSchema

  setup do
    [builder, property, credit_card_processor] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_processor()
      |> PropBuilder.get([:property, :processor])

    [builder, bank_account_processor] =
      builder
      |> PropBuilder.add_processor(type: "ba")
      |> PropBuilder.get([:processor])

    tenant =
      builder
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant()
      |> PropBuilder.add_lease()
      |> PropBuilder.get_requirement(:tenant)

    [_builder, account, payment_source] =
      AccountBuilder.new(:create)
      |> AccountBuilder.put_requirement(:tenant, tenant)
      |> AccountBuilder.put_requirement(:property, property)
      |> AccountBuilder.add_account()
      |> AccountBuilder.add_payment_source()
      |> AccountBuilder.get([:account, :payment_source])

    account =
      account
      |> AppCount.UserHelper.new_account()

    create_args = %{
      processor_id: credit_card_processor.id,
      credit_card_processor_id: credit_card_processor.id,
      bank_account_processor_id: bank_account_processor.id,
      ip_address: "127.0.0.0"
    }

    ~M[account, tenant, payment_source, property, credit_card_processor, bank_account_processor, create_args]
  end

  describe "get_by_transaction_id" do
    setup(~M[account, create_args]) do
      transaction_id = "Authorize-949383ydu839"
      create_args = Map.merge(create_args, %{transaction_id: transaction_id})
      {:ok, _rent_saga} = RentSagaRepo.create_session(account, create_args)
      ~M[transaction_id]
    end

    test ":ok", ~M[transaction_id] do
      # When
      found_rent_saga = RentSagaRepo.get_by_transaction_id(transaction_id)
      assert found_rent_saga.transaction_id == transaction_id
    end
  end

  describe "update" do
    setup(~M[account, create_args]) do
      {:ok, rent_saga} = RentSagaRepo.create_session(account, create_args)
      ~M[rent_saga]
    end

    test ":ok", ~M[payment_source, rent_saga] do
      # When
      result = RentSagaRepo.update(rent_saga, %{payment_source_id: payment_source.id})
      assert {:ok, rent_saga} = result
      assert rent_saga.payment_source_id == payment_source.id
    end

    test ":ok, missing payment source id", ~M[rent_saga] do
      # When
      result = RentSagaRepo.update(rent_saga, %{payment_source_id: nil})
      assert {:ok, _session} = result
    end

    test "update ba_processor", ~M[payment_source, rent_saga, bank_account_processor] do
      # When
      result =
        RentSagaRepo.update(rent_saga, %{
          payment_source_id: payment_source.id,
          bank_account_processor_id: bank_account_processor.id
        })

      assert {:ok, rent_saga} = result
      rent_saga = RentSagaRepo.get_aggregate(rent_saga.id)
      assert rent_saga.bank_account_processor == bank_account_processor
    end

    test "update cc_processor",
         ~M[payment_source, rent_saga,  credit_card_processor] do
      # When
      result =
        RentSagaRepo.update(rent_saga, %{
          payment_source_id: payment_source.id,
          credit_card_processor_id: credit_card_processor.id
        })

      assert {:ok, rent_saga} = result
      rent_saga = RentSagaRepo.get_aggregate(rent_saga.id)
      assert rent_saga.credit_card_processor == credit_card_processor
    end
  end

  describe "create_session" do
    test "get_aggregate", ~M[account, create_args] do
      {:ok, rent_saga} = RentSagaRepo.create_session(account, create_args)

      # When
      rent_saga = RentSagaRepo.get_aggregate(rent_saga.id)

      # Then
      assert Ecto.assoc_loaded?(rent_saga.processor)
      assert Ecto.assoc_loaded?(rent_saga.credit_card_processor)
      assert Ecto.assoc_loaded?(rent_saga.bank_account_processor)
      assert Ecto.assoc_loaded?(rent_saga.account)
      assert Ecto.assoc_loaded?(rent_saga.account.payment_sources)
    end

    def remove_fields(payment_source) do
      Map.drop(payment_source, [:is_tokenized, :inserted_at, :num1, :updated_at, :last_4])
    end
  end

  describe "load_latest/1" do
    test "returns none if none exist" do
      result =
        ClientSchema.new("dasmen", 123_123_123)
        |> RentSagaRepo.load_latest()

      assert is_nil(result)
    end

    test "returns the one if one exists", ~M[account, create_args] do
      {:ok, rent_saga} = RentSagaRepo.create_session(account, create_args)

      # When
      result =
        ClientSchema.new("dasmen", account.id)
        |> RentSagaRepo.load_latest()

      assert result.id == rent_saga.id
    end

    test "returns most recent if many exists", ~M[account, create_args] do
      times =
        AppTime.new()
        |> AppTime.plus(:now, minutes: 0)
        |> AppTime.plus(:minus_five, minutes: -5)
        |> AppTime.plus(:minus_ten, minutes: -10)
        |> AppTime.times()

      create_rent_saga(account, times.minus_five, create_args)
      latest_rent_saga = create_rent_saga(account, times.now, create_args)
      create_rent_saga(account, times.minus_ten, create_args)

      # When
      result =
        ClientSchema.new("dasmen", account.id)
        |> RentSagaRepo.load_latest()

      # Then
      assert result.id == latest_rent_saga.id
    end
  end

  def create_rent_saga(account, time, create_args) do
    create_args = Map.merge(create_args, %{started_at: time, ip_address: "127.0.0.0"})
    {:ok, rent_saga} = RentSagaRepo.create_session(account, create_args)
    rent_saga
  end
end
