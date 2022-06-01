defmodule AppCount.Core.PaymentObserver.StateTest do
  @moduledoc false
  use AppCount.DataCase
  alias AppCount.Core.PaymentObserver.State
  alias AppCount.Core.ClientSchema
  alias AppCount.Accounts.RentSagaRepo
  alias AppCount.Support.AccountBuilder

  @deps %{
    repo: RentSagaRepo,
    tenant_repo: AppCount.Tenants.TenantRepo,
    prop_repo: AppCount.Properties.PropertyRepo,
    tell_yardi_fn: &__MODULE__.no_op/1,
    tell_accounting_fn: &__MODULE__.no_op/1,
    send_receipt_to_tenant_fn: &__MODULE__.no_op/1
  }

  describe "good setup" do
    setup do
      [builder, property, credit_card_processor] =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_processor(type: "cc")
        |> PropBuilder.add_property_setting(sync_payments: true, integration: "Yardi")
        |> PropBuilder.add_property_setting_bank_account()
        |> PropBuilder.get([:property, :processor])

      tenant =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant(external_id: "external_id")
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

      ~M[account, payment_source, credit_card_processor, tenant]
    end

    @tag :slow
    test "payment_confirmed",
         ~M[account, payment_source, credit_card_processor] do
      create_args = %{
        processor_id: credit_card_processor.id,
        payment_source_id: payment_source.id,
        credit_card_processor_id: credit_card_processor.id,
        bank_account_processor_id: nil,
        ip_address: "127.0.0.0",
        transaction_id: "transaction_id"
      }

      {:ok, rent_saga} = RentSagaRepo.create_session(account, create_args)

      state = %State{deps: @deps}

      # When
      result =
        ClientSchema.new("dasmen", rent_saga.id)
        |> State.payment_confirmed(state)

      assert result == :ok
      completed_rent_saga = RentSagaRepo.get(rent_saga.id)

      assert completed_rent_saga
      assert completed_rent_saga.accounting_notified_at
      assert completed_rent_saga.yardi_notified_at
      assert completed_rent_saga.payment_id

      completed_payment = Repo.get(AppCount.Ledgers.Payment, completed_rent_saga.payment_id)

      assert completed_payment
      assert completed_payment.transaction_id == completed_rent_saga.transaction_id
    end

    @tag :slow
    test "payment_confirmed but no Yardi",
         ~M[account, payment_source, credit_card_processor, tenant] do
      create_args = %{
        processor_id: credit_card_processor.id,
        payment_source_id: payment_source.id,
        credit_card_processor_id: credit_card_processor.id,
        bank_account_processor_id: nil,
        ip_address: "127.0.0.0",
        transaction_id: "transaction_id"
      }

      AppCount.Tenants.TenantRepo.update(tenant, %{external_id: nil})

      {:ok, rent_saga} = RentSagaRepo.create_session(account, create_args)

      state = %State{deps: @deps}

      # When
      _result =
        ClientSchema.new("dasmen", rent_saga.id)
        |> State.payment_confirmed(state)

      completed_rent_saga = RentSagaRepo.get(rent_saga.id)
      # Then
      refute completed_rent_saga.yardi_notified_at
    end
  end

  describe " setup with property not accepting payments" do
    setup do
      [builder, property, credit_card_processor] =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_processor(type: "cc")
        |> PropBuilder.add_property_setting(payments_accepted: false)
        |> PropBuilder.add_property_setting_bank_account()
        |> PropBuilder.get([:property, :processor])

      tenant =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant(external_id: "external_id")
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

      ~M[account, payment_source, credit_card_processor, tenant]
    end

    test "error Property not accepting payments",
         ~M[account, payment_source, credit_card_processor] do
      create_args = %{
        processor_id: credit_card_processor.id,
        payment_source_id: payment_source.id,
        credit_card_processor_id: credit_card_processor.id,
        bank_account_processor_id: nil,
        ip_address: "127.0.0.0",
        transaction_id: "transaction_id"
      }

      {:ok, rent_saga} = RentSagaRepo.create_session(account, create_args)

      state = %State{deps: @deps}

      # When
      {:error, actual_message} =
        ClientSchema.new("dasmen", rent_saga.id)
        |> State.payment_confirmed(state)

      completed_rent_saga = RentSagaRepo.get(rent_saga.id)

      expected_error_message = ~s<FAILURE {:error, \"Property not accepting payments\"}>

      assert expected_error_message == completed_rent_saga.message
      assert expected_error_message == actual_message

      refute completed_rent_saga.accounting_notified_at
      refute completed_rent_saga.yardi_notified_at
    end
  end

  describe " setup without default_bank_account_id" do
    setup do
      [builder, property, credit_card_processor] =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_processor(type: "cc")
        |> PropBuilder.add_property_setting()
        |> PropBuilder.get([:property, :processor])

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

      ~M[account, payment_source, credit_card_processor]
    end

    @tag :slow
    test "error when default_bank_account_id is nil",
         ~M[account, payment_source, credit_card_processor] do
      create_args = %{
        processor_id: credit_card_processor.id,
        payment_source_id: payment_source.id,
        credit_card_processor_id: credit_card_processor.id,
        bank_account_processor_id: nil,
        ip_address: "127.0.0.0",
        transaction_id: "transaction_id",
        payment_id: 5555
      }

      {:ok, rent_saga} = RentSagaRepo.create_session(account, create_args)

      state = %State{deps: @deps}

      # When
      {:error, actual_message} =
        ClientSchema.new("dasmen", rent_saga.id)
        |> State.payment_confirmed(state)

      completed_rent_saga = RentSagaRepo.get(rent_saga.id)

      expected_error_message =
        ~s<FAILURE [bank_account_id: {"can't be blank", [validation: :required]}]>

      assert expected_error_message == completed_rent_saga.message
      assert expected_error_message == actual_message

      refute completed_rent_saga.accounting_notified_at
      refute completed_rent_saga.yardi_notified_at
    end
  end

  describe "update_message" do
    setup do
      [_prop_builder, property, tenant] =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_lease()
        |> PropBuilder.get([:property, :tenant])

      [_account_builder, account] =
        AccountBuilder.new(:create)
        |> AccountBuilder.put_requirement(:tenant, tenant)
        |> AccountBuilder.put_requirement(:property, property)
        |> AccountBuilder.add_account()
        |> AccountBuilder.add_payment_source()
        |> AccountBuilder.get([:account])

      create_args = %{
        bank_account_processor_id: nil,
        ip_address: "127.0.0.0",
        transaction_id: "transaction_id"
      }

      ~M[account, create_args ]
    end

    test "ok", ~M[account, create_args] do
      {:ok, rent_saga} = RentSagaRepo.create_session(account, create_args)

      expected_message = "new_message"
      # When
      log_messages =
        capture_log(fn ->
          result = State.update_message(rent_saga.id, expected_message, @deps.repo)

          assert result == :ok
        end)

      assert log_messages =~ ""
      mod_rent_saga = RentSagaRepo.get(rent_saga.id)
      assert mod_rent_saga.message == expected_message
    end

    test "error, no rent_saga found" do
      currupted_rent_saga_id = 0
      expected_message = "new_message"
      # When
      log_messages =
        capture_log(fn ->
          result = State.update_message(currupted_rent_saga_id, expected_message, @deps.repo)

          assert result == {:error, "NOT FOUND rent_saga_id:0 message: new_message"}
        end)

      assert log_messages =~ "[error] NOT FOUND rent_saga_id:0 message: new_message"
    end
  end

  describe "load_context" do
    setup do
      [_prop_builder, property, tenant] =
        PropBuilder.new(:create)
        |> PropBuilder.add_property()
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_lease()
        |> PropBuilder.get([:property, :tenant])

      [_account_builder, account] =
        AccountBuilder.new(:create)
        |> AccountBuilder.put_requirement(:tenant, tenant)
        |> AccountBuilder.put_requirement(:property, property)
        |> AccountBuilder.add_account()
        |> AccountBuilder.add_payment_source()
        |> AccountBuilder.get([:account])

      create_args = %{
        bank_account_processor_id: nil,
        ip_address: "127.0.0.0",
        transaction_id: "transaction_id"
      }

      {:ok, rent_saga} = RentSagaRepo.create_session(account, create_args)

      ~M[account, rent_saga ]
    end

    test ":ok", ~M[account, rent_saga] do
      tenant = %{external_id: "external_id"}

      setting = %{
        sync_payments: "sync_payments",
        default_bank_account_id: "default_bank_account_id",
        integration: "integration"
      }

      # When
      result = State.load_context(rent_saga, account, tenant, setting, @deps.repo)

      assert {:ok, context} = result

      assert Map.keys(context) == [
               :account,
               :client_schema,
               :default_bank_account_id,
               :integration,
               :property_id,
               :rent_saga,
               :sync_payments,
               :tenant,
               :tenant_external_id
             ]
    end

    test "missing setting", ~M[account, rent_saga] do
      tenant = %{}
      nil_setting = nil
      # When
      result = State.load_context(rent_saga, account, tenant, nil_setting, @deps.repo)

      assert result == {:error, "Missing Parameter setting is nil"}
      mod_rent_saga = @deps.repo.get(rent_saga.id)
      assert mod_rent_saga.message == "Missing Parameter setting is nil"
    end

    test "missing tenant", ~M[account, rent_saga] do
      nil_tenant = nil
      setting = %{}
      # When
      result = State.load_context(rent_saga, account, nil_tenant, setting, @deps.repo)

      assert result == {:error, "Missing Parameter tenant is nil"}
      mod_rent_saga = @deps.repo.get(rent_saga.id)
      assert mod_rent_saga.message == "Missing Parameter tenant is nil"
    end
  end

  def no_op(_arg) do
    # used to stub out deps
    :ok
  end
end
