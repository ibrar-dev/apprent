defmodule AppCount.Accounting.RegistersTest do
  use AppCount.DataCase
  alias AppCount.Accounting
  alias AppCount.Properties
  alias AppCount.Repo

  setup do
    {:ok, payee: insert(:payee)}
  end

  test "register CRUD" do
    {:ok, result} =
      Accounting.create_register(%{
        "property_id" => insert(:property).id,
        "account_id" => insert(:account).id,
        "is_default" => true
      })

    assert result.is_default

    Repo.get(Properties.Property, result.property_id)
    |> Repo.preload(:accounts)
    |> Map.get(:accounts)
    |> length
    |> Kernel.==(1)
    |> assert

    {:ok, result} = Accounting.update_register(result.id, %{"is_default" => false})
    refute result.is_default
    Accounting.delete_register(result.id)
    refute Repo.get(Accounting.Register, result.id)
  end
end
