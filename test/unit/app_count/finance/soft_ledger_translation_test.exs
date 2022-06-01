defmodule AppCount.Finance.SoftLedgerTranslationTest do
  use AppCount.DataCase
  alias AppCount.Finance.SoftLedgerTranslation

  describe "id tuples" do
    setup do
      translation = %SoftLedgerTranslation{
        soft_ledger_type: "Location",
        soft_ledger_underscore_id: 843,
        app_count_id: 1234,
        app_count_struct: "AppCount.Properties.Property"
      }

      ~M[translation]
    end

    test "softledger_id", ~M[translation] do
      result = SoftLedgerTranslation.softledger_id(translation)
      assert {"Location", 843} = result
    end

    test "app_count_id", ~M[translation] do
      result = SoftLedgerTranslation.app_count_id(translation)
      assert {"AppCount.Properties.Property", 1234} = result
    end
  end

  describe "changeset/1" do
    test "valid" do
      params = %{
        soft_ledger_type: "Location",
        soft_ledger_underscore_id: 843,
        app_count_id: 1234,
        app_count_struct: "AppCount.Properties.Property"
      }

      # When
      changeset = SoftLedgerTranslation.changeset(%SoftLedgerTranslation{}, params)

      # Then
      assert_valid(changeset)
    end

    test "invalid" do
      params = %{}
      # When
      changeset = SoftLedgerTranslation.changeset(%SoftLedgerTranslation{}, params)

      errors = errors_on(changeset)
      assert errors.soft_ledger_type == ["can't be blank"]
      assert errors.soft_ledger_underscore_id == ["can't be blank"]
      assert errors.app_count_struct == ["can't be blank"]
      assert errors.app_count_id == ["can't be blank"]
    end
  end
end
