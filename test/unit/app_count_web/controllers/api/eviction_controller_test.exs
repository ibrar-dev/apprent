defmodule AppCountWeb.Controllers.API.EvictionControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Properties
  alias AppCount.Tenants
  alias AppCount.Properties.Eviction
  @moduletag :eviction_controller

  setup do
    property = insert(:property)
    unit = insert(:unit, property: property)
    tenant = insert(:tenant)

    {
      :ok,
      lease: insert(:lease, tenants: [tenant], unit: unit),
      admin: admin_with_access([property.id]),
      tenant: tenant,
      unit: unit,
      property: property
    }
  end

  test "create", %{conn: conn, admin: admin, lease: lease} do
    note = "Evicted due to loud belching"

    params = %{
      "eviction" => %{
        "lease_id" => lease.id,
        "file_date" => "2019-01-01",
        "court_date" => "2019-03-20",
        "charge_amount" => 123,
        "notes" => note
      }
    }

    conn
    |> admin_request(admin)
    |> post("https://administration.example.com/api/evictions", params)
    |> json_response(200)

    assert Repo.get_by(Eviction, lease_id: lease.id, notes: note)
    assert Repo.get(Tenants.Tenant, hd(lease.tenants).id).payment_status == "cash"
  end

  test "update", %{conn: conn, admin: admin, lease: lease} do
    params = %{
      "lease_id" => lease.id,
      "file_date" => "2019-01-01",
      "court_date" => "2019-03-20",
      "notes" => "Evicted due to loud belching"
    }

    {:ok, ev} = Properties.create_eviction(params)

    new_params = %{
      "eviction" => %{
        "notes" => "Never mind"
      }
    }

    conn
    |> admin_request(admin)
    |> patch("https://administration.example.com/api/evictions/#{ev.id}", new_params)
    |> json_response(200)

    assert Repo.get(Eviction, ev.id).notes == "Never mind"
  end

  test "delete", %{conn: conn, admin: admin, lease: lease} do
    params = %{
      "lease_id" => lease.id,
      "file_date" => "2019-01-01",
      "court_date" => "2019-03-20",
      "notes" => "Evicted due to loud belching"
    }

    {:ok, ev} = Properties.create_eviction(params)

    conn
    |> admin_request(admin)
    |> delete("https://administration.example.com/api/evictions/#{ev.id}")
    |> json_response(200)

    refute Repo.get(Eviction, ev.id)
  end
end
