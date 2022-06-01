defmodule AppCount.Vendors.VendorTest do
  use AppCount.DataCase
  alias AppCount.Vendors.Vendor

  def new_vendor() do
    Vendor.new("Mickey", "mick@example.com")
  end

  test "create" do
    assert new_vendor()
  end

  test "changeset" do
    vendor = new_vendor()

    changeset = Vendor.changeset(vendor, %{name: "Elon"})
    assert changeset.valid?
  end

  test "invalid changeset out of range " do
    vendor = new_vendor()

    changeset = Vendor.changeset(vendor, %{rating: 6})
    refute changeset.valid?

    assert changeset.errors == [
             rating: {"Out of Range: 1-5", [{:validation, :inclusion}, {:enum, 1..5}]}
           ]
  end

  test "store in db" do
    vendor = new_vendor()

    result =
      Vendor.changeset(vendor, %{name: "Elon"})
      |> Repo.insert()

    assert {:ok, stored_vendor} = result
    assert stored_vendor.id
    assert stored_vendor.inserted_at
    assert stored_vendor.name == "Elon"
  end

  test "add rating and comment" do
    vendor = new_vendor()

    result =
      Vendor.changeset(vendor, %{rating: 5, completion_comment: "Well Done"})
      |> Repo.insert()

    assert {:ok, stored_vendor} = result
    assert stored_vendor.completion_comment == "Well Done"
    assert stored_vendor.rating == 5
  end
end
