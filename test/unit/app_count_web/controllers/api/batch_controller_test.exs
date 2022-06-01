defmodule AppCountWeb.Controllers.API.BatchControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Ledgers.Payment
  alias AppCount.Ledgers.Batch
  @moduletag :batch_controller

  setup do
    property = insert(:property)
    {:ok, admin: admin_with_access([property.id]), property: property}
  end

  test "create", %{conn: conn, admin: admin, property: property} do
    params = %{
      "batch" => %{
        "items" => [
          %{
            "amount" => 250,
            "description" => "Check",
            "payer" => "Christopher Williams",
            "property_id" => property.id,
            "tenant_id" => insert(:tenant).id,
            "transaction_id" => "123456"
          },
          %{
            "amount" => 240,
            "description" => "Check",
            "payer" => "Wewewrw",
            "property_id" => property.id,
            "receipts" => [%{"account_id" => insert(:account).id, "amount" => "240"}],
            "transaction_id" => "414233125"
          },
          %{
            "amount" => 800,
            "description" => "AppRent Payment",
            "payer" => "Reggie Heard",
            "property_id" => property.id,
            "transaction_id" => "11023"
          }
        ],
        "bank_account_id" => insert(:bank_account).id,
        "property_id" => property.id
      }
    }

    conn
    |> admin_request(admin)
    |> post("https://administration.example.com/api/batches", params)
    |> json_response(200)

    batch = hd(Repo.all(Batch))
    payments = Repo.all(Payment)
    assert Enum.all?(payments, &(&1.batch_id == batch.id))
    assert Enum.all?(payments, &(&1.property_id == property.id))
  end

  test "index", %{conn: conn, admin: admin, property: property} do
    batch = insert(:batch, property: property)
    start = AppCount.current_date()
    end_date = Timex.shift(start, days: 2)
    insert(:payment, batch_id: batch.id)

    resp =
      conn
      |> admin_request(admin)
      |> get(
        "https://administration.example.com/api/batches?start=#{start}&end=#{end_date}&property_ids[]=#{
          property.id
        }"
      )
      |> json_response(200)

    assert length(resp) == 1
    assert hd(resp)["id"] == batch.id
  end

  test "update", %{conn: conn, admin: admin, property: property} do
    batch = insert(:batch, property: property)
    insert(:payment, batch_id: batch.id)

    params = %{
      "batch" => %{
        "date_closed" => "2019-02-01"
      }
    }

    conn
    |> admin_request(admin)
    |> patch("https://administration.example.com/api/batches/#{batch.id}", params)
    |> json_response(200)

    batch = Repo.get(Batch, batch.id)
    assert batch.date_closed == %Date{year: 2019, month: 2, day: 1}
    assert batch.closed_by == admin.name
  end

  test "delete", %{conn: conn, admin: admin, property: property} do
    batch = insert(:batch, property: property)

    conn
    |> admin_request(admin)
    |> delete("https://administration.example.com/api/batches/#{batch.id}")
    |> json_response(200)

    refute Repo.get(Batch, batch.id)
  end
end
