defmodule AppCount.Adapters.Twilio.CredentialTest do
  use AppCount.Case
  alias AppCount.Adapters.Twilio.Credential

  test "load from test config" do
    result = Credential.load()
    assert result.sid == "ACb00a5b065ca8143b493adc85b6ac272b"
    assert result.token == "5e026d4b7abf61162fe1a837e6d9d9bc"
    assert result.phone_from == "+15005550006"
  end
end
