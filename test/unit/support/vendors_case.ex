defmodule AppCount.VendorsCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use AppCount.DataCase
      alias AppCount.Vendors.Order
      alias AppCount.Vendors.OrderRepo

      import AppCount.VendorsCase.Helper
    end
  end

  defmodule Helper do
    alias AppCount.Vendors.Order
    alias AppCount.Vendors.Vendor
    alias AppCount.Vendors.Category
    alias AppCount.Repo

    def new_category() do
      Category.new("Best Category")
    end

    def insert_category() do
      new_category()
      |> Category.changeset(%{})
      |> Repo.insert!()
    end

    def new_vendor() do
      Vendor.new("Vendor Inc.", "vendor@example.com")
    end

    def insert_vendor() do
      new_vendor()
      |> Vendor.changeset(%{})
      |> Repo.insert!()
    end

    def new_order() do
      vendor = insert_vendor()
      category = insert_category()

      attrs = %{
        status: "Open",
        vendor_id: vendor.id,
        category_id: category.id,
        uuid: Ecto.UUID.generate(),
        ticket: "ticket",
        priority: 4
      }

      Order.new(attrs)
    end

    def insert_order() do
      new_order()
      |> Order.changeset(%{})
      |> Repo.insert!()
    end
  end
end
