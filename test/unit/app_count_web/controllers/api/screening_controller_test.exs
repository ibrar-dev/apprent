defmodule AppCountWeb.Controllers.API.ScreeningControllerTest do
  use AppCount.Case
  use AppCountWeb.ConnCase
  import AppCount.{Factory, LeaseHelper}
  import Mock
  alias AppCount.Repo
  alias AppCount.Leases.Screening
  @moduletag :screening_controller
  @sample_response """
  <?xml version="1.0"?><BackgroundReports userId="" password="" databaseset="">
  <BackgroundReportPackage><ReferenceId><![CDATA[56]]></ReferenceId><OrderId>920048</OrderId>
  <ScreeningStatus><OrderStatus>x:pending</OrderStatus></ScreeningStatus></BackgroundReportPackage></BackgroundReports>"
  """

  setup do
    admin = AppCount.UserHelper.new_admin()

    lease =
      insert_lease(%{
        charges: [
          rent: 500
        ]
      })

    insert(:processor, property: lease.unit.property)
    {:ok, [admin: admin, lease: lease]}
  end

  test "create for application", %{conn: conn, admin: admin, lease: lease} do
    application = insert(:rent_application, property: lease.unit.property)
    person = insert(:rent_apply_person, application: application)
    insert(:history, application: application)
    params = %{"id" => application.id, "rent" => 1000}

    with_mock TenantSafe.Request,
              [:passthrough],
              submit: fn _ -> {:ok, @sample_response} end do
      conn
      |> admin_request(admin)
      |> post("http://administration.example.com/api/screenings", %{"application" => params})
      |> json_response(200)
    end

    assert Repo.get_by(Screening, person_id: person.id).email == person.email
  end

  test "create for lease", %{conn: conn, admin: admin, lease: lease} do
    params = %{
      "first_name" => "Pete",
      "last_name" => "Smith",
      "email" => "something@somewhere.com",
      "phone" => "123-456-6789",
      "ssn" => "111-22-3333",
      "dob" => "1980-01-01",
      "street" => "123 Main St.",
      "city" => "Chicago",
      "state" => "IL",
      "zip" => "12345",
      "lease_id" => lease.id,
      "income" => 1000
    }

    with_mock TenantSafe.Request,
              [:passthrough],
              submit: fn _ -> {:ok, @sample_response} end do
      conn
      |> admin_request(admin)
      |> post("http://administration.example.com/api/screenings", %{"screening" => params})
      |> json_response(200)
    end

    assert Repo.get_by(Screening, lease_id: lease.id).first_name == "Pete"
  end

  test "approve", %{conn: conn, admin: admin, lease: lease} do
    screening = insert(:screening, person: nil, lease: lease)

    conn
    |> admin_request(admin)
    |> patch("http://administration.example.com/api/screenings/#{screening.id}", %{
      "approve" => true
    })
    |> json_response(200)

    %{tenant: tenant} =
      Repo.get(Screening, screening.id)
      |> Repo.preload(tenant: :leases)

    assert tenant
    assert hd(tenant.leases).id == lease.id
  end

  #  test "get status", %{conn: conn, admin: admin} do
  #
  #  end

  test "delete", %{conn: conn, admin: admin, lease: lease} do
    screening = insert(:screening, person: nil, lease: lease)

    conn
    |> admin_request(admin)
    |> delete("http://administration.example.com/api/screenings/#{screening.id}")
    |> json_response(200)

    refute Repo.get(Screening, screening.id)
  end
end
