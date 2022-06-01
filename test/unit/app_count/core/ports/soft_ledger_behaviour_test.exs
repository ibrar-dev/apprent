defmodule AppCount.Core.Ports.SoftLedgerBehaviourTest do
  use AppCount.DataCase, async: true
  use AppCount.Core.Ports.SoftLedgerBehaviour, :alias_requests_and_responses

  alias AppCount.Core.Ports.SoftLedgerBehaviour.GetJournalResponse.Data,
    as: GetJournalResponseData

  alias AppCount.Core.Ports.SoftLedgerBehaviour.CreateJournalResponse.Transaction,
    as: CreateJournalResponseTransaction

  describe "GetJournalResponse" do
    test "new/1 empty" do
      params = %{totalItems: 0, data: []}

      # When
      struct = GetJournalResponse.new(params)

      assert %GetJournalResponse{totalItems: 0, data: []} = struct
    end

    test "new/1 with one journal entry" do
      one = %{
        Location: :not_set,
        SystemJobId: :not_set,
        _id: :not_set,
        amount: :not_set,
        attachments: [],
        createdAt: :not_set,
        currency: :not_set,
        entryType: :not_set,
        number: :not_set,
        postedDate: :not_set,
        reference: :not_set,
        reverseDate: :not_set,
        sourceLedger: :not_set,
        status: :not_set,
        transactionDate: :not_set,
        updatedAt: :not_set
      }

      params = %{totalItems: 1, data: [one]}

      # When
      struct = GetJournalResponse.new(params)

      expected_data = %GetJournalResponseData{
        Location: :not_set,
        SystemJobId: :not_set,
        _id: :not_set,
        amount: :not_set,
        attachments: [],
        createdAt: :not_set,
        currency: :not_set,
        entryType: :not_set,
        number: :not_set,
        postedDate: :not_set,
        reference: :not_set,
        reverseDate: :not_set,
        sourceLedger: :not_set,
        status: :not_set,
        transactionDate: :not_set,
        updatedAt: :not_set
      }

      assert %GetJournalResponse{totalItems: 1, data: [^expected_data]} = struct
    end
  end

  describe "CreateJournalResponse" do
    test "new/1" do
      transaction_params = %{
        _id: :not_set,
        description: :not_set,
        debit: :not_set,
        credit: :not_set,
        transactionDate: :not_set,
        postedDate: :not_set,
        reconcileId: :not_set,
        currency: :not_set,
        consolidated: :not_set,
        reversing: :not_set,
        elimination: :not_set,
        elim2: :not_set,
        SystemJobId: :not_set,
        CostCenterId: :not_set,
        LedgerAccountId: :not_set,
        JobId: :not_set,
        ProductId: :not_set,
        LocationId: :not_set,
        InvoiceId: :not_set,
        BillId: :not_set,
        AgentId: :not_set,
        Vendorid: :not_set,
        ICLocationId: :not_set,
        CashReceiptId: :not_set,
        VendorCreditId: :not_set,
        ICAccountId: :not_set,
        PaymentId: :not_set,
        ForexRateId: :not_set,
        ProductionId: :not_set,
        JournalId: :not_set
      }

      params = %{
        _id: :not_set,
        number: :not_set,
        status: :not_set,
        entryType: :not_set,
        sourceLedger: :not_set,
        reference: :not_set,
        notes: :not_set,
        attachments: [],
        reverseDate: :not_set,
        icDoc: :not_set,
        createdAt: :not_set,
        updatedAt: :not_set,
        AccountingPeriodId: :not_set,
        transactions: [transaction_params]
      }

      # When
      struct = CreateJournalResponse.new(params)
      # and
      expected_transaction = %CreateJournalResponseTransaction{
        _id: :not_set,
        description: :not_set,
        debit: :not_set,
        credit: :not_set,
        transactionDate: :not_set,
        postedDate: :not_set,
        reconcileId: :not_set,
        currency: :not_set,
        consolidated: :not_set,
        reversing: :not_set,
        elimination: :not_set,
        elim2: :not_set,
        SystemJobId: :not_set,
        CostCenterId: :not_set,
        LedgerAccountId: :not_set,
        JobId: :not_set,
        ProductId: :not_set,
        LocationId: :not_set,
        InvoiceId: :not_set,
        BillId: :not_set,
        AgentId: :not_set,
        Vendorid: :not_set,
        ICLocationId: :not_set,
        CashReceiptId: :not_set,
        VendorCreditId: :not_set,
        ICAccountId: :not_set,
        PaymentId: :not_set,
        ForexRateId: :not_set,
        ProductionId: :not_set,
        JournalId: :not_set
      }

      expected_result = %CreateJournalResponse{
        _id: :not_set,
        number: :not_set,
        status: :not_set,
        entryType: :not_set,
        sourceLedger: :not_set,
        reference: :not_set,
        notes: :not_set,
        attachments: [],
        reverseDate: :not_set,
        icDoc: :not_set,
        createdAt: :not_set,
        updatedAt: :not_set,
        AccountingPeriodId: :not_set,
        transactions: [expected_transaction]
      }

      # then
      assert expected_result == struct
    end
  end

  describe "DeleteJournalRequest" do
    test "invalid" do
      params = %{foo: 0, data: []}

      # When
      struct = DeleteJournalRequest.new(params)

      refute Map.keys(params) in Map.keys(struct)
    end

    test "valid" do
      params = %{id: 1230}

      # When
      %{id: id} = DeleteJournalRequest.new(params)

      assert id == 1230
    end
  end

  describe "CreateUpdateAccountRequest" do
    test "valid changeset" do
      random_num = Enum.random(10_000_000..99_999_999)

      request_params = %{
        name: "account.name",
        naturalBalance: "credit",
        number: "#{random_num}",
        type: "Asset",
        subtype: "Fixed Asset"
      }

      # When
      result = CreateUpdateAccountRequest.changeset(%CreateUpdateAccountRequest{}, request_params)

      assert_valid(result)
    end

    test "subtype too short" do
      invalid_subtype = "a"

      # When
      changeset =
        CreateUpdateAccountRequest.changeset(%CreateUpdateAccountRequest{}, %{
          subtype: invalid_subtype
        })

      refute_valid(changeset)
      assert "should be at least 2 character(s)" in errors_on(changeset).subtype
    end

    test "subtype too long" do
      invalid_subtype = String.pad_leading("", 256, "a")

      # When
      changeset =
        CreateUpdateAccountRequest.changeset(%CreateUpdateAccountRequest{}, %{
          subtype: invalid_subtype
        })

      refute_valid(changeset)
      assert "should be at most 255 character(s)" in errors_on(changeset).subtype
    end

    test "invalid blanks" do
      request_params = %{
        name: nil,
        number: nil,
        type: nil,
        subtype: nil
      }

      # When
      changeset =
        CreateUpdateAccountRequest.changeset(%CreateUpdateAccountRequest{}, request_params)

      assert "can't be blank" in errors_on(changeset).naturalBalance
      assert "can't be blank" in errors_on(changeset).name
      assert "can't be blank" in errors_on(changeset).type
      assert "can't be blank" in errors_on(changeset).subtype
      assert "can't be blank" in errors_on(changeset).number
    end

    test "invalid fields" do
      short_num = "1"

      request_params = %{
        name: "account.name",
        naturalBalance: "blah",
        number: short_num,
        type: "Error",
        subtype: "subtype"
      }

      # When
      changeset =
        CreateUpdateAccountRequest.changeset(%CreateUpdateAccountRequest{}, request_params)

      assert ~s[must be "credit" or "debit"] in errors_on(changeset).naturalBalance
      assert "should be 8 character(s)" in errors_on(changeset).number

      assert ~s[must be "Asset", "Liability", "Equity", "Revenue", or "Expense"] in errors_on(
               changeset
             ).type
    end
  end

  describe "CreateJournalRequest" do
    test "default" do
      request = %CreateJournalRequest{}

      assert request.currency == "USD"
    end

    test "valid changeset" do
      request_params = %{
        status: "posted",
        entryType: "Standard",
        # Enum: "Financial" "AR" "AP"
        sourceLedger: "Financial",
        reference: "blah",
        # Minimum 2 rows required. SUM(debits) = SUM(credits).
        transactions: []
      }

      # When

      result =
        %CreateJournalRequest{}
        |> CreateJournalRequest.changeset(request_params)

      assert_valid(result)
    end

    test "invalid blanks" do
      request_params = %{
        status: nil,
        entryType: nil,
        sourceLedger: nil,
        reference: nil
        # WIP transactions: []
      }

      # When
      changeset = CreateJournalRequest.changeset(%CreateJournalRequest{}, request_params)

      assert "can't be blank" in errors_on(changeset).status
      assert "can't be blank" in errors_on(changeset).entryType
      assert "can't be blank" in errors_on(changeset).sourceLedger
      assert "can't be blank" in errors_on(changeset).reference
      # WIP assert "can't be blank" in errors_on(changeset).transactions
    end

    test "invalid fields" do
      request_params = %{
        status: "wrong value",
        entryType: "wrong value",
        sourceLedger: "wrong value",
        reference: "something"
      }

      # When
      changeset = CreateJournalRequest.changeset(%CreateJournalRequest{}, request_params)

      assert ~s[must be "draft" or "posted"] in errors_on(changeset).status
      assert ~s[must be "Standard" or "Reversing"] in errors_on(changeset).entryType
      assert ~s[must be "Financial", "AR", or "AP"] in errors_on(changeset).sourceLedger
    end
  end

  describe "CreateJournalTransactionRequest" do
    test "default" do
      root_location_id = AppCount.Adapters.SoftLedger.Config.load().parent_id

      # When
      %{LocationId: location_id} = %CreateJournalTransactionRequest{}

      assert root_location_id == location_id
    end

    test "valid changeset" do
      request_params = %{
        transactionDate: "2000-01-01",
        postedDate: "2000-01-01",
        debit: "0",
        credit: "2000.00",
        LedgerAccountId: 12345
      }

      # When

      result =
        %CreateJournalTransactionRequest{}
        |> CreateJournalTransactionRequest.changeset(request_params)

      assert_valid(result)
    end

    test "debit and credit are both zero" do
      request_params = %{
        transactionDate: "2000-01-01",
        postedDate: "2000-01-01",
        debit: "0",
        credit: "0",
        LedgerAccountId: 12345
      }

      # When
      changeset =
        %CreateJournalTransactionRequest{}
        |> CreateJournalTransactionRequest.changeset(request_params)

      assert ~s["credit" and "debit" may not both be zero] in errors_on(changeset).credit
      # assert ~s[may not both "credit" and "debit" be zero] in errors_on(changeset).debit
    end

    test "transactionDate Cannot be in the future." do
      request_params = %{
        transactionDate: "3000-01-01",
        postedDate: "2000-01-01",
        debit: "0",
        credit: "1000",
        LedgerAccountId: 12345
      }

      # When
      changeset =
        %CreateJournalTransactionRequest{}
        |> CreateJournalTransactionRequest.changeset(request_params)

      assert ~s[Cannot be in the future] in errors_on(changeset).transactionDate
    end

    test "invalid blanks" do
      request_params = %{
        transactionDate: nil,
        postedDate: nil,
        debit: nil,
        credit: nil,
        LedgerAccountId: nil
      }

      # When
      changeset =
        CreateJournalTransactionRequest.changeset(
          %CreateJournalTransactionRequest{},
          request_params
        )

      assert "can't be blank" in errors_on(changeset).transactionDate
      assert "can't be blank" in errors_on(changeset).postedDate
      assert "can't be blank" in errors_on(changeset).debit
      assert "can't be blank" in errors_on(changeset).credit
      assert "can't be blank" in Map.get(errors_on(changeset), :LedgerAccountId)
    end
  end
end
