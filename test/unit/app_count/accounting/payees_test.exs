defmodule AppCount.Accounting.PayeesTest do
  use AppCount.DataCase
  alias AppCount.Accounting
  alias AppCount.Repo

  setup do
    {:ok, payee: insert(:payee)}
  end

  test "list_payees", %{payee: payee} do
    result = Accounting.list_payees()
    assert length(result) == 1
    assert hd(result).id == payee.id
  end

  test "create_payee" do
    {:ok, result} =
      Accounting.create_payee(%{
        "name" => "Some Body",
        "phone" => "555-5555"
      })

    assert result.name == "Some Body"
    assert result.id
  end

  test "update_payee", %{payee: payee} do
    {:ok, result} =
      Accounting.update_payee(
        payee.id,
        %{
          "name" => "Some Body Else",
          "phone" => "555-5555"
        }
      )

    assert result.name == "Some Body Else"
  end

  test "delete_payee", %{payee: payee} do
    Accounting.delete_payee(payee.id)
    refute Repo.get(Accounting.Payee, payee.id)
  end

  test "get_payee", %{payee: payee} do
    assert Accounting.get_payee(payee.id)
  end
end
