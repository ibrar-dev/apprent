defmodule AppCount.Adapters.SoftLedger.CredentialTest do
  use AppCount.Case, async: true
  alias AppCount.Adapters.SoftLedger.Credential

  test "load from test config" do
    result = Credential.load()
    assert result.grant_type == "client_credentials"
    assert result.audience == "https://sl-sb.softledger.com"
    assert result.client_id == "kblnl4ynjhzeEX5OlTgKUZ5UQbvG1m9Q"
    assert result.tenantUUID == "01978f23-a529-4cdd-938e-219ea9e720b7"

    assert result.client_secret ==
             "BtH7ROLm0HHr7F-U2HMiPxkY5-HHmQga-WESKBritpbzSC8Uw5J1shU4LrUlZzix"
  end
end
