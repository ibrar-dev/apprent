defmodule AppCount.ScreeningTest do
  use AppCount.DataCase
  alias AppCount.Leases.Utils.Screenings
  use Bamboo.Test, shared: true
  import Mock
  @moduletag :screening

  #  @sample_response """
  #  <?xml version="1.0"?><BackgroundReports userId="" password="" databaseset="">
  #  <BackgroundReportPackage><ReferenceId><![CDATA[56]]></ReferenceId><OrderId>920048</OrderId>
  #  <ScreeningStatus><OrderStatus>x:pending</OrderStatus></ScreeningStatus></BackgroundReportPackage></BackgroundReports>"
  #  """

  setup do
    person = insert(:rent_apply_person)
    property_id = Repo.get(AppCount.RentApply.RentApplication, person.application_id).property_id
    property = Repo.get(AppCount.Properties.Property, property_id)
    insert(:processor, property: property)
    admin = admin_with_access([property_id])
    {:ok, person: person, property_id: property_id, property: property, admin: admin}
  end

  test "create_screening works and sends email for non-instascreen", %{
    person: person,
    property_id: property_id,
    admin: _admin
  } do
    params = %{
      property_id: property_id,
      person_id: person.id,
      first_name: "Joe",
      last_name: "Clean",
      phone: "1234567890",
      email: "joeclean@gmail.com",
      street: "123 Sesame St.",
      city: "Chicago",
      state: "IL",
      zip: "53210",
      income: 1500,
      rent: 1000,
      linked_orders: [],
      dob: Timex.shift(AppCount.current_date(), years: -30),
      ssn: "111-22-3333",
      decision: "Dunno",
      status: "pending",
      order_id: "86018",
      url: "http://idontknowanymore.com"
    }

    client = AppCount.Public.get_client_by_schema("dasmen")

    with_mock TenantSafe.SubmitOrder,
              [:passthrough],
              submit: fn _, _ ->
                %{order_id: "1234"}
              end do
      {:ok, screen} = Screenings.create_screening(params, false, client.client_schema)

      #
      # Move this to a lower level test
      # assert_email_delivered_with(
      #   subject: "[AppRent] There is a screened applicant.",
      #   html_body: ~r/There is an application that has been screened at/,
      #   to: [nil: admin.email]
      # )

      assert is_nil(Repo.get(AppCount.Leases.Screening, screen.id, prefix: client.client_schema)) ==
               false
    end
  end

  test "create_screening works and sends email for instascreen", %{
    person: person,
    property_id: property_id,
    admin: _admin
  } do
    params = %{
      property_id: property_id,
      person_id: person.id,
      first_name: "Joe",
      last_name: "Clean",
      phone: "1234567890",
      email: "joeclean@gmail.com",
      street: "123 Sesame St.",
      city: "Chicago",
      state: "IL",
      zip: "53210",
      income: 1500,
      rent: 1000,
      linked_orders: [],
      dob: Timex.shift(AppCount.current_date(), years: -30),
      ssn: "111-22-3333",
      decision: "Dunno",
      status: "pending",
      order_id: "86018",
      url: "http://idontknowanymore.com"
    }

    client = AppCount.Public.get_client_by_schema("dasmen")

    with_mock TenantSafe.SubmitOrder,
              [:passthrough],
              submit: fn _, _ ->
                %{order_id: "1234"}
              end do
      {:ok, screen} = Screenings.create_screening(params, true, client.client_schema)

      # Move this t a lower lever test
      # assert_email_delivered_with(
      #   subject: "[AppRent] There is an instantly screened applicant.",
      #   html_body: ~r/An applicant has applied and has been instantly screened at/,
      #   to: [nil: admin.email]
      # )

      assert is_nil(Repo.get(AppCount.Leases.Screening, screen.id, prefix: client.client_schema)) ==
               false
    end
  end
end
