defmodule AppCount.Twilio.MessagingTest do
  use AppCount.Case
  alias AppCount.Twilio.Messaging

  def fake_msg(:no_media) do
    %{
      "AccountSid" => "ACb00a5b065ca8143b493adc85b6ac272b",
      "ApiVersion" => "2010-04-01",
      "Body" => "Testing Testing 1 2 3",
      "From" => "+11234567890",
      "FromCity" => "NEW YORK",
      "FromCountry" => "US",
      "FromState" => "NY",
      "FromZip" => "10001",
      "MessageSid" => "sidThesnAke",
      "NumMedia" => "0",
      "NumSegments" => "1",
      "SmsMessageSid" => "thiSiSTheSidFortheMessage",
      "SmsSid" => "thiSiSTheSidFortheMessage",
      "SmsStatus" => "received",
      "To" => "+10987654321",
      "ToCity" => "NEW YORK",
      "ToCountry" => "US",
      "ToState" => "NY",
      "ToZip" => "10001"
    }
  end

  def fake_msg(:media) do
    %{
      "AccountSid" => "ACb00a5b065ca8143b493adc85b6ac272b",
      "ApiVersion" => "2010-04-01",
      "Body" => "Testing Testing 1 2 3",
      "From" => "+11234567890",
      "FromCity" => "NEW YORK",
      "FromCountry" => "US",
      "FromState" => "NY",
      "FromZip" => "10001",
      "MediaContentType0" => "image/jpeg",
      "MediaUrl0" => "https://thisisaurl.jpeg",
      "MessageSid" => "sidThesnAke",
      "NumMedia" => "1",
      "NumSegments" => "1",
      "SmsMessageSid" => "thiSiSTheSidFortheMessage",
      "SmsSid" => "thiSiSTheSidFortheMessage",
      "SmsStatus" => "received",
      "To" => "+10987654321",
      "ToCity" => "NEW YORK",
      "ToCountry" => "US",
      "ToState" => "NY",
      "ToZip" => "10001"
    }
  end

  test "new_incoming/1 no media" do
    res =
      fake_msg(:no_media)
      |> Messaging.new_incoming()

    assert res.direction == "incoming"
    assert res.body == "Testing Testing 1 2 3"
    assert res.external_id == "thiSiSTheSidFortheMessage"
    refute res.media_urls
  end

  test "new_incoming/1 media" do
    res =
      fake_msg(:media)
      |> Messaging.new_incoming()

    assert res.direction == "incoming"
    assert length(res.media_types) == 1
    assert length(res.media_urls) == 1
  end
end
