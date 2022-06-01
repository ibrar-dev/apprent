defmodule AppCountCom.Utils.StorageCase do
  use AppCount.DataCase
  alias AppCountCom.Utils.Storage
  alias AppCount.Messaging.Email
  @moduletag :email_storage

  setup do
    tenant = insert(:tenant)

    email = %Bamboo.Email{
      attachments: [
        %{
          filename: "sample.png",
          path: Path.expand("../../resources/sample.png", __DIR__),
          content_type: "image/png"
        }
      ],
      from: {nil, "someone@somewhere.com"},
      subject: "Subject",
      to: tenant.email,
      html_body: "<p>lovely little HTML fragment here</p>"
    }

    {:ok, email: email, tenant: tenant}
  end

  test "stores emails", %{email: email, tenant: tenant} do
    Storage.store_email(email)
    email = Repo.get_by(Email, tenant_id: tenant.id)
    assert email
    assert email.to == tenant.email
    assert email.from == "someone@somewhere.com"
  end
end
