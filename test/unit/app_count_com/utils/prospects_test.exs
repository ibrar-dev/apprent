defmodule AppCountCom.Mailer.ProspectsCase do
  use AppCount.DataCase
  alias AppCountCom.Prospects
  use Bamboo.Test, shared: true
  @moduletag :mailer_prospects

  test "contact_prospect" do
    memo_info = %{
      notes: "Something good",
      admin: "Smooth Talker",
      prospect: build(:prospect),
      property: build(:mailer_property)
    }

    Prospects.contact_prospect(memo_info)

    assert_email_delivered_with(
      subject:
        "[AppRent] #{memo_info.admin} is reaching out to you from #{memo_info.property.name}",
      html_body: ~r/Thank you for your interest in/,
      to: [
        nil: memo_info.prospect.email
      ]
    )
  end

  test "notify_of_closure" do
    info = %{
      name: "Somebody's name",
      date: AppCount.current_date(),
      start_time: 123_456,
      reason: "Dunno",
      email: "someone@example.com",
      property: build(:mailer_property)
    }

    Prospects.notify_of_closure(info)

    assert_email_delivered_with(
      subject: "[AppRent] A tour you have scheduled needs to be re-scheduled",
      html_body: ~r/Unfortunately we need to re schedule this tour for another date./,
      to: [
        nil: info.email
      ]
    )
  end
end
