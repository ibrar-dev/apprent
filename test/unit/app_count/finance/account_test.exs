defmodule AppCount.Finance.AccountsTest do
  use AppCount.DataCase
  alias AppCount.Finance.Account

  setup do
    random_num = Enum.random(10_000_000..99_999_999)

    params = %{
      name: "asset one",
      number: "#{random_num}",
      natural_balance: "credit",
      type: "Asset",
      subtype: "Fixed Asset",
      description: "hi"
    }

    ~M[params]
  end

  test "build" do
    assert %Account{
      name: "asset one",
      number: "10000000",
      natural_balance: "credit",
      type: "Asset",
      subtype: "Fixed Asset",
      description: "hi"
    }
  end

  describe "validations" do
    test "valid changeset", ~M[params] do
      # When
      changeset = Account.changeset(%Account{}, params)

      assert_valid(changeset)
    end

    test "invalid-ly long description", ~M[params] do
      invalid_description = String.pad_leading("", 256, "a")
      params = %{params | description: invalid_description}

      changeset = Account.changeset(%Account{}, params)

      refute_valid(changeset)
      assert "should be at most 255 character(s)" in errors_on(changeset).description
    end

    test "invalid non-numeric number" do
      num = "1234567A"

      # When
      changeset = Account.changeset(%Account{}, %{number: num})
      refute_valid(changeset)

      assert "must be 8 numeric digits" in errors_on(changeset).number
    end

    test "invalid numeric number" do
      num = "1234 678"
      # When
      changeset = Account.changeset(%Account{}, %{number: num})

      refute_valid(changeset)
      assert "must be 8 numeric digits" in errors_on(changeset).number
    end

    test "subtype too short" do
      invalid_subtype = "a"

      # When
      changeset = Account.changeset(%Account{}, %{subtype: invalid_subtype})

      refute_valid(changeset)
      assert "should be at least 2 character(s)" in errors_on(changeset).subtype
    end

    test "subtype too long" do
      invalid_subtype = String.pad_leading("", 256, "a")

      # When
      changeset = Account.changeset(%Account{}, %{subtype: invalid_subtype})

      refute_valid(changeset)
      assert "should be at most 255 character(s)" in errors_on(changeset).subtype
    end

    test "invalid blanks" do
      request_params = %{}

      # When
      changeset = Account.changeset(%Account{}, request_params)

      # Then
      refute_valid(changeset)
      assert "can't be blank" in errors_on(changeset).natural_balance
      assert "can't be blank" in errors_on(changeset).name
      assert "can't be blank" in errors_on(changeset).type
      assert "can't be blank" in errors_on(changeset).number
    end

    test "invalid fields" do
      short_num = "1"

      request_params = %{
        name: "account.name",
        natural_balance: "blah",
        number: short_num,
        type: "Error",
        subtype: "Fixed Asset"
      }

      # When
      changeset = Account.changeset(%Account{}, request_params)

      refute_valid(changeset)
      assert ~s[must be "credit" or "debit"] in errors_on(changeset).natural_balance
      assert "must be 8 digits" in errors_on(changeset).number

      assert ~s[must be "Asset", "Liability", "Equity", "Revenue", or "Expense"] in errors_on(
               changeset
             ).type
    end

    test "duplicate name", ~M[params] do
      {:ok, _existing_account} =
        %Account{}
        |> Account.changeset(params)
        |> Repo.insert()

      new_attrs = Map.merge(params, %{number: "87654321"})

      # When
      assert {:error, changeset} =
               Account.changeset(%Account{}, new_attrs)
               |> Repo.insert()

      refute_valid(changeset)
      assert "has already been taken" in errors_on(changeset).name
    end

    test "duplicate number", ~M[params] do
      {:ok, _existing_account} =
        %Account{}
        |> Account.changeset(params)
        |> Repo.insert()

      new_attrs = Map.merge(params, %{name: "Mr. T"})

      # When
      assert {:error, changeset} =
               Account.changeset(%Account{}, new_attrs)
               |> Repo.insert()

      refute_valid(changeset)
      assert ~s[has already been taken] in errors_on(changeset).number
    end
  end
end
