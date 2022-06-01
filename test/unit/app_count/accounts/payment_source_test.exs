defmodule AppCount.Accounts.PaymentSourceTest do
  alias AppCount.Accounts.PaymentSource
  use AppCount.Case, async: true

  describe "changeset/2" do
    test "requires name be present" do
      cs = PaymentSource.changeset(%PaymentSource{}, %{name: nil})

      refute_valid(cs)
      assert "can't be blank" in errors_on(cs).name
    end

    test "requires name be not-blank" do
      cs = PaymentSource.changeset(%PaymentSource{}, %{name: ""})

      refute_valid(cs)
      assert "can't be blank" in errors_on(cs).name
    end

    test "allows present name" do
      cs = PaymentSource.changeset(%PaymentSource{}, %{name: "Devaney"})

      # No error on name
      refute Map.has_key?(errors_on(cs), :name)
    end

    test "allows bank-account type" do
      cs = PaymentSource.changeset(%PaymentSource{}, %{type: "ba"})

      refute_valid(cs)
      refute Map.has_key?(errors_on(cs), :type)
    end

    test "allows credit-card type" do
      cs = PaymentSource.changeset(%PaymentSource{}, %{type: "cc"})

      refute_valid(cs)
      refute Map.has_key?(errors_on(cs), :type)
    end

    test "disallows other types" do
      cs = PaymentSource.changeset(%PaymentSource{}, %{type: "lol an invalid type"})

      refute_valid(cs)
      assert "must be ba or cc" in errors_on(cs).type
    end

    test "allows subtype on credit card" do
      cs =
        PaymentSource.changeset(%PaymentSource{}, %{
          type: "cc",
          subtype: "platinum card"
        })

      # No error on subtype
      refute Map.has_key?(errors_on(cs), :subtype)
    end

    test "allows blank subtype on credit card" do
      cs = PaymentSource.changeset(%PaymentSource{}, %{type: "cc", subtype: nil})

      # No error on subtype
      refute Map.has_key?(errors_on(cs), :subtype)
    end

    test "allows subtype -checking- on bank account" do
      cs = PaymentSource.changeset(%PaymentSource{}, %{type: "ba", subtype: "checking"})

      # No error on subtype
      refute Map.has_key?(errors_on(cs), :subtype)
    end

    test "allows subtype -savings- on bank account" do
      cs = PaymentSource.changeset(%PaymentSource{}, %{type: "ba", subtype: "savings"})

      # No error on subtype
      refute Map.has_key?(errors_on(cs), :subtype)
    end

    test "disallows other types on bank account" do
      cs = PaymentSource.changeset(%PaymentSource{}, %{type: "ba", subtype: "sheckings"})

      assert "must be checking or savings" in errors_on(cs).subtype
    end

    test "requires subtype on bank account" do
      cs = PaymentSource.changeset(%PaymentSource{}, %{type: "ba", subtype: ""})

      assert "must be checking or savings" in errors_on(cs).subtype
    end

    test "requires non-nil subtype on bank account" do
      cs = PaymentSource.changeset(%PaymentSource{}, %{type: "ba", subtype: nil})

      assert "must be checking or savings" in errors_on(cs).subtype
    end

    test "requires num1 be present" do
      cs = PaymentSource.changeset(%PaymentSource{}, %{num1: 123})

      # No error on num1 - it's here!
      refute Map.has_key?(errors_on(cs), :num1)
    end

    test "errors on blank num1" do
      cs = PaymentSource.changeset(%PaymentSource{}, %{num1: nil})

      assert "can't be blank" in errors_on(cs).num1
    end

    test "requires num2 be present" do
      cs = PaymentSource.changeset(%PaymentSource{}, %{num2: 123})

      # No error on num2 - it's here!
      refute Map.has_key?(errors_on(cs), :num2)
    end

    test "errors on blank num2" do
      cs = PaymentSource.changeset(%PaymentSource{}, %{num2: nil})

      assert "can't be blank" in errors_on(cs).num2
    end

    test "requires brand be present" do
      cs = PaymentSource.changeset(%PaymentSource{}, %{brand: "WISA"})

      # No issue with brand
      refute Map.has_key?(errors_on(cs), :brand)
    end

    test "requires account_id be present" do
      cs = PaymentSource.changeset(%PaymentSource{}, %{account_id: 12})

      # No issue with account id
      refute Map.has_key?(errors_on(cs), :account_id)
    end
  end
end
