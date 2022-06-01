defmodule AppCount.Settings.CredentialSetsCase do
  use AppCount.DataCase
  alias AppCount.Settings.Utils.CredentialSets
  @moduletag :credential_sets

  setup do
    {
      :ok,
      credential_set:
        insert(
          :credential_set,
          credentials: [
            %{name: "username", value: "user name"},
            %{name: "password", value: "password"},
            %{name: "id", value: "1234567890"}
          ]
        )
    }
  end

  test "credentials_for_provider", %{credential_set: credential_set} do
    {:ok, credentials} = CredentialSets.credentials_for_provider(credential_set.provider)
    assert credentials["username"] == "user name"
    assert credentials["password"] == "password"
    assert credentials["id"] == "1234567890"
  end

  test "credentials_for_provider when missing" do
    assert CredentialSets.credentials_for_provider("random") == {:error, :not_found}
  end

  test "credentials_for_provider!", %{credential_set: credential_set} do
    credentials = CredentialSets.credentials_for_provider!(credential_set.provider)
    assert credentials["username"] == "user name"
    assert credentials["password"] == "password"
    assert credentials["id"] == "1234567890"
  end

  test "credentials_for_provider! when missing" do
    assert_raise RuntimeError, "No credentials found for provider: random", fn ->
      CredentialSets.credentials_for_provider!("random")
    end
  end
end
