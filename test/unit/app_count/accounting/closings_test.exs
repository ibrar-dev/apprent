defmodule AppCount.Accounting.ClosingsTest do
  use AppCount.DataCase
  alias AppCount.Accounting
  alias AppCount.Repo
  alias AppCount.Accounting.Closing
  alias AppCount.Core.ClientSchema

  @moduletag :accounting_closings

  setup do
    property = insert(:property)

    admin =
      admin_with_access([property.id])
      |> Map.put(:client_schema, "dasmen")

    {:ok, property: property, admin: admin}
  end

  test "create_closing", %{property: property, admin: admin} do
    params = %{
      "property_id" => property.id,
      "month" => "2019-01-01",
      "closed_on" => "2019-02-11",
      "type" => "payables"
    }

    new_admin = AppCount.UserHelper.new_admin()

    refute Accounting.create_closing(ClientSchema.new("dasmen", new_admin), params)

    {:ok, %Closing{} = closing} =
      Accounting.create_closing(ClientSchema.new("dasmen", admin), params)

    assert closing.admin_id == admin.id
    assert closing.property_id == property.id
  end

  test "delete_closing", %{property: property, admin: admin} do
    params = %{
      "property_id" => property.id,
      "month" => "2019-01-01",
      "closed_on" => "2019-02-11",
      "type" => "payables"
    }

    {:ok, %Closing{} = closing} =
      Accounting.create_closing(ClientSchema.new("dasmen", admin), params)

    new_admin = AppCount.UserHelper.new_admin()

    refute Accounting.create_closing(ClientSchema.new("dasmen", new_admin), params)

    refute Accounting.delete_closing(ClientSchema.new("dasmen", new_admin), closing.id)
    {:ok, %Closing{}} = Accounting.delete_closing(ClientSchema.new("dasmen", admin), closing.id)
    refute Repo.get(Closing, closing.id)
  end

  test "calculates correct post date", %{property: property, admin: admin} do
    params = %{
      "property_id" => property.id,
      "month" => "2019-02-01",
      "closed_on" => "2019-03-11",
      "type" => "payables"
    }

    {:ok, %Closing{}} = Accounting.create_closing(ClientSchema.new("dasmen", admin), params)
    inserted_at = Timex.parse!("2019-03-01", "{YYYY}-{M}-{D}")
    start = Timex.parse!("2019-02-15", "{YYYY}-{M}-{D}")

    assert Accounting.get_post_month(property.id, inserted_at, start, "payables") == %Date{
             year: 2019,
             day: 1,
             month: 2
           }

    later_date = Timex.shift(inserted_at, days: 15)

    assert Accounting.get_post_month(property.id, later_date, start, "payables") == %Date{
             year: 2019,
             day: 1,
             month: 3
           }

    params = %{
      "property_id" => property.id,
      "month" => "2019-03-01",
      "closed_on" => "2019-03-11",
      "type" => "payables"
    }

    {:ok, %Closing{}} = Accounting.create_closing(ClientSchema.new("dasmen", admin), params)

    assert Accounting.get_post_month(property.id, later_date, start, "payables") == %Date{
             year: 2019,
             day: 1,
             month: 4
           }
  end
end
