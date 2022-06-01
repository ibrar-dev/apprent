defmodule AppCount.Finance.SoftLedgerTranslationRepoTest do
  use AppCount.DataCase
  alias AppCount.Finance.SoftLedgerTranslationRepo
  alias AppCount.Finance.SoftLedgerTranslation
  alias AppCount.Core.DomainEvent

  test "insert" do
    params = %{
      soft_ledger_type: "Location",
      soft_ledger_underscore_id: 1234,
      app_count_struct: "AppCount.Properties.Property",
      app_count_id: 987
    }

    # When
    {:ok, translation} = SoftLedgerTranslationRepo.insert(params)
    assert %SoftLedgerTranslation{} = translation
  end

  describe "soft_ledger_account_id/1" do
    test "not_found" do
      app_count_id = 9_876_543

      # When
      result = SoftLedgerTranslationRepo.soft_ledger_account_id(app_count_id)

      assert result == nil
    end

    test "found" do
      app_count_id = 9_876_543
      soft_ledger_underscore_id = 999_999

      params = %{
        soft_ledger_type: "Account",
        soft_ledger_underscore_id: soft_ledger_underscore_id,
        app_count_struct: "AppCount.Finance.Account",
        app_count_id: app_count_id
      }

      {:ok, translation} = SoftLedgerTranslationRepo.insert(params)
      assert %SoftLedgerTranslation{} = translation

      # When
      result = SoftLedgerTranslationRepo.soft_ledger_account_id(app_count_id)

      assert result == soft_ledger_underscore_id
    end
  end

  describe "translation exists" do
    setup do
      app_count_id = 999

      params = %{
        soft_ledger_type: "Location",
        soft_ledger_underscore_id: 1234,
        app_count_struct: "AppCount.Properties.Property",
        app_count_id: app_count_id
      }

      {:ok, translation} = SoftLedgerTranslationRepo.insert(params)
      ~M[translation]
    end

    test "publishes created event", ~M[translation] do
      %{app_count_struct: app_count_struct, app_count_id: app_count_id} = translation

      # Then
      assert_receive %DomainEvent{
        topic: "soft_ledger__translations",
        name: "created",
        content: %{},
        subject_name: ^app_count_struct,
        subject_id: ^app_count_id,
        source: AppCount.Finance.SoftLedgerTranslationRepo
      }
    end

    test "get_by_app_count found", ~M[ translation] do
      %{
        soft_ledger_type: _soft_ledger_type,
        soft_ledger_underscore_id: soft_ledger_underscore_id,
        app_count_struct: app_count_struct,
        app_count_id: app_count_id
      } = translation

      # When
      translation = SoftLedgerTranslationRepo.get_by_app_count(app_count_struct, app_count_id)

      # Then
      assert translation.soft_ledger_underscore_id == soft_ledger_underscore_id
      assert translation.soft_ledger_type == "Location"
    end

    test "get_by_app_count not found" do
      # When
      result = SoftLedgerTranslationRepo.get_by_app_count("BLAH", 9090)

      # Then
      assert result == nil
    end
  end
end
