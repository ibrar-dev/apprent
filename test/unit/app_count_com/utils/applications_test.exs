defmodule AppCountCom.ApplicationsCase do
  use AppCount.DataCase
  alias AppCountCom.Applications
  use Bamboo.Test, shared: true
  @moduletag :mailer_applications

  setup do
    property =
      build(:property)
      |> Map.merge(%{icon: "http://something", logo: "http://something"})

    {:ok, property: property}
  end

  test "application_received", %{property: property} do
    payment = build(:payment)
    Applications.application_received("someone@exammple.com", property, payment)

    assert_email_delivered_with(
      subject: "[AppRent] Your application to #{property.name}",
      html_body: ~r/Thank you for submitting an application/,
      to: [
        nil: "someone@exammple.com"
      ]
    )
  end

  test "application_submitted", %{property: property} do
    payment = %{
      id: 123,
      total: 150,
      application_fee: 100,
      admin_fee: 50
    }

    info = %{id: 100, payment: payment, applicants: "People", floor_plan: "1 Bedroom"}
    admin = build(:admin)
    Applications.application_submitted(admin, property, info)

    assert_email_delivered_with(
      subject: "[AppRent] New Application - #{property.name}",
      html_body: ~r/Let's process the application and get back to them ASAP/,
      to: [
        nil: admin.email
      ]
    )
  end

  test "application_summary", %{property: property} do
    application = %{
      id: 123,
      property: %{
        "name" => property.name
      },
      persons: [%{"full_name" => "Someone Personbody", "status" => "Lease Holder"}],
      inserted_at: AppCount.current_time()
    }

    admin = build(:admin)
    Applications.application_summary(admin, AppCount.current_time(), [application])

    assert_email_delivered_with(
      subject: "[AppRent] Application Summary",
      html_body: ~r/The following applications have been received for the period/,
      to: [
        nil: admin.email
      ]
    )
  end

  test "application_approved", %{property: property} do
    email = "applicant@example.com"
    application = build(:rent_application, property: property)
    Applications.application_approved(email, application)

    assert_email_delivered_with(
      subject: "[AppRent] Application Approved",
      html_body: ~r/In order to finalize your application please pay the/,
      to: [
        nil: email
      ]
    )
  end

  test "send_payment_url", %{property: property} do
    email = "someone@somewhere.com"
    Applications.send_payment_url(property, "https://etc", %{name: "Some name", email: email})

    assert_email_delivered_with(
      subject: "[AppRent] Administration Fee Payment Portal",
      html_body: ~r/Please click the button below to pay the Administration Fee/,
      to: [
        nil: email
      ]
    )
  end

  test "send_daily_applications" do
    admin = build(:admin)

    property = %{
      id: 100,
      property: "Property",
      sum: 130,
      total_apps: 1,
      icon: "property_icon_url.jpeg",
      apps: [
        %{
          "payment_amount" => 130,
          "people" => [%{"full_name" => "John Johnson"}],
          "inserted_at" => AppCount.current_time()
        }
      ]
    }

    Applications.send_daily_applications([property], admin)

    assert_email_delivered_with(
      subject: "[AppRent] Daily Application Summary",
      html_body: ~r/The following applications have been received so far today/,
      to: [
        nil: admin.email
      ]
    )
  end
end
