defmodule AppCount.Mail.MailTest do
  use AppCount.DataCase
  alias AppCount.Repo
  @sns_message File.read!(Path.expand("../../resources/RingCentralEmail.txt", __DIR__))
  @moduletag :mail

  setup do
    property = insert(:property)
    insert(:phone_line, property: property, number: "(845) 533-2058")
    {:ok, property: property}
  end

  test "processes Ring Central prospect email", %{property: property} do
    AppCount.Mail.process_mail(@sns_message)

    assert Repo.get_by(
             AppCount.Prospects.Prospect,
             property_id: property.id,
             name: "Astor David",
             phone: "(646) 379-5257",
             contact_type: "Phone"
           )
  end

  test "processes Ring Central maintenance email", %{property: property} do
    message =
      @sns_message
      |> String.replace(~r/leasing\@contact\.apprent\.com/, "maintenance@contact.apprent.com")

    AppCount.Mail.process_mail(message)

    assert_receive {:start, AppCount.Maintenance.Utils.Orders, :assign_status_task,
                    [_id, "unassigned"]}

    assert Repo.get_by(
             AppCount.Maintenance.Order,
             property_id: property.id,
             created_by: "Missed Call from Astor David (646) 379-5257"
           )

    Repo.delete_all(AppCount.Maintenance.Order)
    AppCount.Mail.process_mail(message)

    assert Repo.get_by(
             AppCount.Maintenance.Order,
             property_id: property.id,
             created_by: "Missed Call from Astor David (646) 379-5257"
           )
  end
end
