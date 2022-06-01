defmodule AppCountWeb.Controllers.API.LeaseControllerTest do
  use AppCountWeb.ConnCase
  alias AppCount.Accounting
  alias AppCount.Repo
  alias AppCount.Leases.Lease
  alias AppCount.Core.ClientSchema

  @moduletag :lease_controller

  setup do
    new_admin = AppCount.UserHelper.new_admin()
    {:ok, lease: insert(:lease), admin: new_admin}
  end

  #  test "create", %{conn: conn, admin: admin} do
  #  end

  test "update", %{conn: conn, admin: admin, lease: lease} do
    params = %{
      "lease" => %{
        "actual_move_in" => nil,
        "actual_move_out" => nil,
        "charges" => [
          %{
            "account" => "Rent",
            "account_id" => Accounting.SpecialAccounts.get_account(:rent).id,
            "amount" => 900,
            "from_date" => nil,
            "to_date" => nil
          }
        ],
        "deposit_amount" => "666",
        "editMode" => true,
        "end_date" => "2020-02-29",
        "eviction" => %{
          "court_date" => nil,
          "file_date" => nil,
          "id" => nil,
          "notes" => nil
        },
        "expected_move_in" => "2019-02-07",
        "id" => lease.id,
        "is_current" => true,
        "move_out_date" => nil,
        "notes" => nil,
        "notice_date" => nil,
        "persons" => [
          %{
            "email" => nil,
            "first_name" => "Joseph",
            "id" => hd(lease.tenants).id,
            "last_name" => "Jackson",
            "middle_name" => nil,
            "phone" => nil,
            "status" => "Lease Holder"
          }
        ],
        "property" => %{
          "id" => lease.unit.property_id,
          "name" => "Lavana Falls",
          "notice_period" => 60
        },
        "start_date" => "2019-02-07",
        "termination" => nil,
        "unit" => %{
          "id" => lease.unit_id,
          "number" => lease.unit.number
        },
        "unit_id" => lease.unit_id
      }
    }

    conn
    |> admin_request(admin)
    |> patch("http://administration.example.com/api/leases/#{lease.id}", params)
    |> json_response(200)

    Repo.get(Lease, lease.id).deposit_amount
    |> Decimal.equal?(Decimal.new(666))
    |> assert
  end

  test "lock", %{conn: conn, lease: lease, admin: admin} do
    lease2 = insert(:lease, renewal: lease)

    params = %{
      "actual_move_out" => "#{AppCount.current_date()}",
      "check" => %{
        "amount" => 350,
        "tenant_id" => hd(lease.tenants).id,
        "admin" => admin.name,
        "date" => "#{lease.end_date}",
        "number" => "9999999",
        "bank_account_id" => insert(:bank_account).id
      }
    }

    conn
    |> admin_request(admin)
    |> patch("http://administration.example.com/api/leases/#{lease.id}", %{"lock" => params})
    |> json_response(200)

    assert Repo.get(Lease, lease.id).closed
    assert Repo.get(Lease, lease2.id).closed
  end

  test "unlock", %{conn: conn, lease: lease, admin: admin} do
    lease2 = insert(:lease, renewal: lease, closed: true)
    AppCount.Leases.update_lease(lease.id, ClientSchema.new("dasmen", %{closed: true}))

    conn
    |> admin_request(admin)
    |> patch("http://administration.example.com/api/leases/#{lease.id}", %{"unlock" => lease.id})
    |> json_response(200)

    refute Repo.get(Lease, lease.id).closed
    refute Repo.get(Lease, lease2.id).closed
  end

  test "delete", %{conn: conn, lease: lease} do
    super_admin = AppCount.UserHelper.new_admin(%{roles: ["Super Admin"]})

    conn
    |> admin_request(super_admin)
    |> delete("http://administration.example.com/api/leases/#{lease.id}")
    |> json_response(200)

    refute Repo.get(Lease, lease.id)
  end
end
