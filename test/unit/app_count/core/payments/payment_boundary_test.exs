defmodule AppCount.Core.PaymentBoundaryTest do
  use AppCount.Case, async: true
  alias AppCount.Core.PaymentBoundary
  alias AppCount.Core.RentSaga
  alias AppCount.Accounts.Account
  alias AppCount.Core.Clock
  alias AppCount.Core.ClientSchema
  @moduletag :payment_boundary

  alias AppCount.Accounts.PaymentSource

  defmodule PaymentPortParrot do
    use TestParrot
    parrot(:payment_port, :process_payment, {:ok, %{transaction_id: "Authorize-transaction_id"}})
  end

  defmodule PropertyRepoParrot do
    use TestParrot
    parrot(:prop_repo, :credit_card_payment_processor, {:ok, %{id: 777}})
    parrot(:prop_repo, :bank_account_payment_processor, {:ok, %{id: 777}})
  end

  defmodule RentSagaRepoParrot do
    use TestParrot

    @default_session %RentSaga{
      account: %Account{id: 1234, property_id: 42},
      payment_source: %{type: "cc", inserted_at: Clock.now({-10, :minutes})},
      id: 234,
      property_id: 42
    }

    parrot(:ps_repo, :create, {:ok, @default_session})
    parrot(:ps_repo, :create_session, {:ok, @default_session})
    parrot(:ps_repo, :load_account, {:ok, %Account{}})

    parrot(:ps_repo, :get_aggregate, @default_session)
    parrot(:ps_repo, :get, @default_session)
    parrot(:ps_repo, :update, {:ok, @default_session})
    parrot(:ps_repo, :load_latest, nil)
    parrot(:ps_repo, :reload, @default_session)
  end

  defmodule AccountsParrot do
    use TestParrot

    parrot(:accounts, :account_lock_exists?, false)
  end

  @deps %{
    port: PaymentPortParrot,
    rent_saga_repo: RentSagaRepoParrot,
    prop_repo: PropertyRepoParrot,
    accounts: AccountsParrot
  }

  @hour 60 * 60

  setup do
    account_id = 1234
    property_id = 42

    account = %Account{
      id: account_id,
      property_id: property_id,
      tenant: %{payment_status: "approved"}
    }

    processors = %{
      credit_card_processor_id: %{id: 994_949},
      bank_account_processor_id: %{id: 963_539}
    }

    ~M[account, processors, property_id]
  end

  describe "account_not_locked?" do
    test "returns {:ok, account} if account is approved", ~M[account] do
      # When
      result = PaymentBoundary.account_not_locked?(account, @deps)

      # Then
      assert result == {:ok, true}
    end

    test "returns {:error, error_message} if account has a lock", ~M[account] do
      AccountsParrot.say_account_lock_exists?(true)
      # When
      result = PaymentBoundary.account_not_locked?(account, @deps)

      expected_error_message =
        "Your payment cannot be processed because your online account is locked. You can submit payment using our MoneyGram partnership. Please contact the local leasing office if you have any questions or need further assistance."

      # Then
      assert result == {:error, expected_error_message}
    end
  end

  describe "load_account/1" do
    test "one", ~M[account] do
      {:ok, result} = PaymentBoundary.load_account(account.id, @deps)
      assert result == %Account{}
    end
  end

  describe "load_processors/1" do
    test ":ok", ~M[account, property_id] do
      # When
      {:ok, _processors} = PaymentBoundary.load_processors(account, @deps)
      assert_receive {:credit_card_payment_processor, ^property_id}
      assert_receive {:bank_account_payment_processor, ^property_id}
    end

    test "error", ~M[account] do
      PropertyRepoParrot.say_bank_account_payment_processor({:error, "BankAccount Not Found"})
      # When
      {:ok, processors} = PaymentBoundary.load_processors(account, @deps)

      assert processors.credit_card_processor_id
      refute processors.bank_account_processor_id
    end
  end

  describe "create_rent_saga/1" do
    test "creates a rent_saga, returning an aggregate",
         ~M[account, processors, property_id] do
      account_id = account.id
      rent_saga_id = 234
      amount_in_cents = 100_000
      agreement_text = "I do"

      # When
      {:ok, rent_saga} =
        PaymentBoundary.create_rent_saga(
          [
            account: account,
            processors: processors,
            ip_address: "127.0.0.0",
            amount_in_cents: amount_in_cents,
            agreement_text: agreement_text,
            originating_device: "web"
          ],
          @deps
        )

      assert rent_saga.account.id == account_id
      assert rent_saga.id == rent_saga_id
      assert rent_saga.property_id == account.property_id

      assert_receive {:create_session, _account,
                      %{
                        credit_card_processor_id: _credit_card_processor_id,
                        bank_account_processor_id: _bank_account_processor_id,
                        started_at: _now_ish,
                        amount_in_cents: ^amount_in_cents,
                        agreement_text: ^agreement_text,
                        property_id: ^property_id,
                        originating_device: "web"
                      }}

      assert_receive {:get_aggregate, ^rent_saga_id}
    end

    test "ok: last_payment was 12 hours and 10 seconds ago", ~M[account, processors] do
      minus_12_hours_and_10 = -12 * @hour - 10
      # Given
      prev_rent_saga_started_at = DateTime.utc_now() |> DateTime.add(minus_12_hours_and_10)

      prev_rent_saga = %RentSaga{
        account: account,
        id: 234,
        started_at: prev_rent_saga_started_at
      }

      amount_in_cents = 100_000
      agreement_text = "agreement_text"

      RentSagaRepoParrot.say_load_latest(prev_rent_saga)
      # When
      result =
        PaymentBoundary.create_rent_saga(
          [
            account: account,
            processors: processors,
            ip_address: "127.0.0.0",
            amount_in_cents: amount_in_cents,
            agreement_text: agreement_text,
            originating_device: "web"
          ],
          @deps
        )

      # Then
      assert {:ok, _rent_saga} = result
    end

    test "error: last_payment was 50 seconds ago", ~M[account] do
      last_payment_at = -50
      # Given
      prev_rent_saga_started_at = DateTime.utc_now() |> DateTime.add(last_payment_at)

      prev_rent_saga = %RentSaga{
        account: %Account{id: account.id},
        id: 234,
        started_at: prev_rent_saga_started_at
      }

      # When
      result = PaymentBoundary.allow_rent_saga_creation?(prev_rent_saga, @deps)

      # Then
      assert {:error, "Please wait a few minutes and then try your payment again"} = result

      assert_receive {:update, _rent_saga, %{message: denied_message}}

      assert denied_message =~ "denied attempt 20"
    end
  end

  describe "select_payment_source" do
    test "select cc " do
      payment_source_id = 1
      account_id = 2_223_223

      payment_source = %PaymentSource{
        type: "cc",
        name: "user",
        num1: "4111111111111111",
        num2: "123",
        brand: "visa",
        active: true,
        lock: nil,
        account_id: account_id,
        inserted_at: Clock.now({-10, :minutes})
      }

      credit_card_processor = %{id: 948, password: "failed decrypt"}

      rent_saga = %RentSaga{
        payment_source: payment_source,
        credit_card_processor: credit_card_processor,
        id: 44444,
        account: %{property_id: 42}
      }

      RentSagaRepoParrot.say_get_aggregate(rent_saga)

      # When
      {:ok, _rent_saga} =
        PaymentBoundary.select_payment_source(
          rent_saga,
          payment_source_id,
          @deps
        )

      # Then
      assert_receive {:get_aggregate, 44444}
      assert_receive {:update, _rent_saga, %{payment_source_id: 1}}
      assert_receive {:get_aggregate, _rent_saga}
      assert_receive {:update, _rent_saga, %{processor_id: 948}}
      assert_receive {:get_aggregate, _}
    end
  end

  describe "payment_source_not_locked?/2" do
    test "when source is not locked" do
      minus_12_hours_and_10 = -12 * 3600 - 10
      # Given
      lock_date = DateTime.utc_now() |> DateTime.add(minus_12_hours_and_10)

      payment_source = %PaymentSource{
        type: "cc",
        name: "user",
        num1: "4111111111111111",
        num2: "123",
        brand: "visa",
        active: true,
        lock: lock_date,
        account_id: 1,
        inserted_at: Clock.now({-10, :minutes})
      }

      session = %RentSaga{payment_source: payment_source}

      result = PaymentBoundary.payment_source_not_locked?(session)
      assert {:ok, true} = result
    end

    test "when source is locked" do
      minus_11_hours_and_59 = -11 * 3600 + 59
      # Given
      lock_date = DateTime.utc_now() |> DateTime.add(minus_11_hours_and_59)

      payment_source = %PaymentSource{
        type: "cc",
        name: "user",
        num1: "4111111111111111",
        num2: "123",
        brand: "visa",
        active: true,
        lock: lock_date,
        account_id: 1,
        inserted_at: Clock.now({-10, :minutes})
      }

      session = %RentSaga{payment_source: payment_source}

      result = PaymentBoundary.payment_source_not_locked?(session)
      assert {:error, "Payment source locked, as it has been used in the last 12 hours"} = result
    end
  end

  describe "select_processor" do
    test "select cc " do
      account_id = 2_223_223

      payment_source = %PaymentSource{
        type: "cc",
        name: "user",
        num1: "4111111111111111",
        num2: "123",
        brand: "visa",
        active: true,
        lock: nil,
        account_id: account_id,
        inserted_at: Clock.now({-10, :minutes})
      }

      credit_card_processor = %{id: 948, password: "failed decrypt"}

      rent_saga = %RentSaga{
        payment_source: payment_source,
        credit_card_processor: credit_card_processor,
        id: 44444,
        account: %{property_id: 42}
      }

      # When
      result = PaymentBoundary.select_processor(rent_saga, @deps.rent_saga_repo)

      # Then
      assert result == {rent_saga, credit_card_processor.id}
    end
  end

  describe "post_payment/3" do
    test "success: payment_confirmed_at " do
      amount_in_cents = 10_000
      agreement_text = "I agree"

      payment_source = %{
        id: "When I grow up I want to be a real PaymentSource",
        inserted_at: Clock.now({-10, :minutes})
      }

      rent_saga = %RentSaga{
        id: 999,
        payment_source_id: 123,
        payment_source: payment_source,
        amount_in_cents: amount_in_cents,
        agreement_text: agreement_text
      }

      # When
      {:ok, _rent_saga} = PaymentBoundary.post_payment(rent_saga, @deps)
      assert_receive {:update, _rent_saga, %{payment_confirmed_at: _payment_confirmed_at}}
    end

    test "success: event payment_confirmed " do
      AppCount.Core.PaymentTopic.subscribe()
      amount_in_cents = 100_000
      surcharge_in_cents = 3_000
      total_amount_in_cents = 103_000
      total_amount_in_dollars = 1030.0
      agreement_text = "I agree"

      payment_source = %{
        id: "When I grow up I want to be a real PaymentSource",
        inserted_at: Clock.now({-10, :minutes})
      }

      rent_saga = %AppCount.Core.RentSaga{
        id: 999,
        payment_source_id: 123,
        payment_source: payment_source,
        amount_in_cents: amount_in_cents,
        surcharge_in_cents: surcharge_in_cents,
        agreement_text: agreement_text
      }

      # When
      PaymentBoundary.post_payment(rent_saga, @deps)

      assert_receive %AppCount.Core.DomainEvent{
        topic: "payments",
        name: "payment_confirmed",
        content: %ClientSchema{name: nil, attrs: %{rent_saga_id: 234}},
        source: PaymentBoundary
      }

      assert_receive {:update, _rent_saga, %{payment_confirmed_at: _payment_confirmed_at}}
      assert_receive {:update, _, %{transaction_id: "Authorize-transaction_id"}}
      assert_receive {:get_aggregate, _}
      assert_receive {:process_payment, ^total_amount_in_dollars, %{type: "cc"}, _processor}
      assert_receive {:update, _, %{total_amount_in_cents: ^total_amount_in_cents}}
    end

    test "error: zero amount" do
      agreement_text = "I agree"
      error_amount = 0

      rent_saga = %AppCount.Core.RentSaga{
        payment_source_id: 123,
        amount_in_cents: error_amount,
        agreement_text: agreement_text
      }

      # When
      {:error, _rent_saga} = PaymentBoundary.post_payment(rent_saga, @deps)

      assert_receive {:update, _, %{message: "Payment declined - amount must be positive"}}
    end

    test "error: max amount" do
      agreement_text = "I agree"
      error_amount = 3000 * 100 + 1

      rent_saga = %AppCount.Core.RentSaga{
        payment_source_id: 123,
        amount_in_cents: error_amount,
        agreement_text: agreement_text
      }

      # When
      {:error, _rent_saga} = PaymentBoundary.post_payment(rent_saga, @deps)

      assert_receive {:update, _, %{message: "Payment declined - amount must be $3000 or less"}}
    end

    test "error: server timeout" do
      agreement_text = "I agree"

      rent_saga = %AppCount.Core.RentSaga{
        payment_source_id: 123,
        amount_in_cents: 1000,
        agreement_text: agreement_text
      }

      PaymentPortParrot.say_process_payment({:error, %HTTPoison.Error{id: nil, reason: :timeout}})
      # When
      {:error, _rent_saga} = PaymentBoundary.post_payment(rent_saga, @deps)

      assert_receive {:update, _, %{message: "Payment declined - server timeout"}}
    end

    test "error: negative amount" do
      agreement_text = "I agree"
      error_amount_in_cents = -100_000

      rent_saga = %AppCount.Core.RentSaga{
        payment_source_id: 123,
        amount_in_cents: error_amount_in_cents,
        agreement_text: agreement_text
      }

      # When
      {:error, _rent_saga} = PaymentBoundary.post_payment(rent_saga, @deps)

      assert_receive {:update, _, %{message: "Payment declined - amount must be positive"}}
    end

    test "error: nil amount" do
      agreement_text = "I agree"
      error_amount_in_cents = nil

      rent_saga = %AppCount.Core.RentSaga{
        payment_source_id: 123,
        amount_in_cents: error_amount_in_cents,
        agreement_text: agreement_text
      }

      # When
      {:error, _rent_saga} = PaymentBoundary.post_payment(rent_saga, @deps)

      assert_receive {:update, _, %{message: "Payment declined - amount must be positive"}}
    end

    test "error: no payment source selected" do
      agreement_text = "I agree"
      amount_in_cents = 100_000

      rent_saga = %AppCount.Core.RentSaga{
        payment_source_id: :not_set,
        amount_in_cents: amount_in_cents,
        agreement_text: agreement_text
      }

      # When
      {:error, _rent_saga} = PaymentBoundary.post_payment(rent_saga, @deps)

      assert_receive {:update, _, %{message: "Payment declined - select a payment source"}}
    end

    test "{:error, message}: from port " do
      amount_in_cents = 10_000
      agreement_text = "I agree"

      payment_source = %{
        id: "When I grow up I want to be a real PaymentSource",
        inserted_at: Clock.now({-10, :minutes})
      }

      rent_saga = %AppCount.Core.RentSaga{
        payment_source_id: 123,
        payment_source: payment_source,
        amount_in_cents: amount_in_cents,
        agreement_text: agreement_text
      }

      PaymentPortParrot.say_process_payment({:error, "No Good, Very Bad Result"})
      # When
      {:error, _payment_source} = PaymentBoundary.post_payment(rent_saga, @deps)
      assert_receive {:update, _, %{message: "No Good, Very Bad Result"}}
    end
  end

  describe "update_message" do
    test "single first message" do
      rent_saga = %AppCount.Core.RentSaga{}

      # When
      PaymentBoundary.update_message(
        rent_saga,
        "an error has occured",
        @deps.rent_saga_repo
      )

      assert_receive {:update, _, %{message: "an error has occured"}}
    end

    test "multiple messages" do
      rent_saga = %AppCount.Core.RentSaga{message: "first message"}

      # When
      PaymentBoundary.update_message(
        rent_saga,
        "second message",
        @deps.rent_saga_repo
      )

      assert_receive {:update, _, %{message: "first message; second message"}}
    end
  end

  describe "update_failed_at" do
    test "first update_failed_at" do
      rent_saga = %AppCount.Core.RentSaga{}

      # When
      PaymentBoundary.update_failed_at(rent_saga, @deps.rent_saga_repo)

      assert_receive {:update, _, %{failed_at: _times_stamp}}
    end

    test "multiple update_failed_at" do
      minute_ago = Clock.now({-1, :minutes})
      rent_saga = %AppCount.Core.RentSaga{failed_at: minute_ago}

      # When
      PaymentBoundary.update_failed_at(rent_saga, @deps.rent_saga_repo)

      refute_receive {:update, _, %{failed_at: _times_stamp}}
    end
  end

  describe "put_zip_code_confirmed_at" do
    test "do not apply with ba" do
      payment_source = %PaymentSource{
        type: "ba",
        inserted_at: Clock.now({-10, :minutes})
      }

      rent_saga = %AppCount.Core.RentSaga{
        payment_source: payment_source,
        amount_in_cents: 100_000
      }

      # When
      result = PaymentBoundary.put_zip_code_confirmed_at(rent_saga, @deps.rent_saga_repo)

      # Then
      assert result == rent_saga
      refute_receive {:update, _, %{zip_code_confirmed_at: _}}
    end

    test "apply with CC" do
      rent_saga = %AppCount.Core.RentSaga{
        processor: %{type: "cc"},
        account_id: 123,
        started_at: Clock.now(),
        ip_address: "1.1.1.1"
      }

      # When
      _result = PaymentBoundary.put_zip_code_confirmed_at(rent_saga, @deps.rent_saga_repo)

      # Then
      assert_receive {:update, _, %{zip_code_confirmed_at: _}}
    end
  end

  describe "put_cvv_confirmed_at" do
    test "do not apply with ba" do
      payment_source = %PaymentSource{
        type: "ba",
        inserted_at: Clock.now({-10, :minutes})
      }

      rent_saga = %AppCount.Core.RentSaga{
        payment_source: payment_source,
        amount_in_cents: 100_000
      }

      # When
      result = PaymentBoundary.put_cvv_confirmed_at(rent_saga, @deps.rent_saga_repo)

      # Then
      assert result == rent_saga
      refute_receive {:update, _, %{cvv_confirmed_at: _}}
    end

    test "apply with CC" do
      inserted_at = Clock.now({-10, :minutes})

      payment_source = %PaymentSource{
        type: "cc",
        inserted_at: inserted_at
      }

      rent_saga = %AppCount.Core.RentSaga{
        payment_source: payment_source,
        account_id: 123,
        started_at: Clock.now(),
        ip_address: "1.1.1.1",
        processor: %{type: "cc"}
      }

      # When
      _result = PaymentBoundary.put_cvv_confirmed_at(rent_saga, @deps.rent_saga_repo)

      # Then
      assert_receive {:update, _, %{cvv_confirmed_at: ^inserted_at}}
    end
  end

  describe "add_surcharge" do
    test "do not apply with ba" do
      rent_saga = %AppCount.Core.RentSaga{
        processor: %{type: "ba"},
        amount_in_cents: 100_000
      }

      # When
      result = PaymentBoundary.put_credit_card_surcharge(rent_saga, @deps)

      # Then
      assert result == {:ok, rent_saga}
      refute_receive {:update, _, %{surcharge_in_cents: _}}
    end

    test "with cc" do
      assert_surcharge(100, 3)
      assert_surcharge(132, 4)
      assert_surcharge(133, 4)
      assert_surcharge(134, 4)
      assert_surcharge(166, 5)
      assert_surcharge(167, 5)
      assert_surcharge(100_000, 3_000)
      assert_surcharge(200_000, 6_000)
    end

    def assert_surcharge(input, expected) do
      rent_saga = %AppCount.Core.RentSaga{
        processor: %{type: "cc"},
        amount_in_cents: input
      }

      # When
      _result = PaymentBoundary.put_credit_card_surcharge(rent_saga, @deps)

      assert_receive {:update, _, %{surcharge_in_cents: surcharge_in_cents}}
      assert surcharge_in_cents == expected
    end
  end
end
