defmodule AppCount.SendApplicationReportTaskTest do
  use AppCount.DataCase
  use Bamboo.Test, shared: true
  alias AppCount.Tasks.Workers.SendApplicationReport, as: Subject
  @moduletag :send_application_report

  setup do
    application1 = insert(:full_rent_application)
    application2 = insert(:full_rent_application)
    admin1 = admin_with_access([application1.property.id], roles: ["Regional"])
    admin2 = admin_with_access([application2.property.id], roles: ["Regional"])
    {:ok, admins: [admin1, admin2], applications: [application1, application2]}
  end

  @tag :flaky
  test "sends application summaries to relevant admins", %{
    admins: [admin1, admin2],
    applications: [application1, application2]
  } do
    Subject.perform()
    [person1] = application1.persons
    [person2] = application2.persons

    assert_email_delivered_with(
      subject: "[AppRent] Daily Application Summary",
      html_body: ~r/#{person1.full_name}/m,
      to: [
        nil: admin1.email
      ]
    )

    assert_email_delivered_with(
      subject: "[AppRent] Daily Application Summary",
      html_body: ~r/#{person2.full_name}/m,
      to: [
        nil: admin2.email
      ]
    )
  end
end
