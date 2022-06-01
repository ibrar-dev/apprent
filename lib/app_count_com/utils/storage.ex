defmodule AppCountCom.Utils.Storage do
  alias AppCount.Messaging.Utils.Emails
  # AppCount.Core.Tasker.start because there are scenarios where store_email/1 errors out
  def async_store_email(%Bamboo.Email{} = email) do
    AppCount.Core.Tasker.start(fn -> store_email(email) end)
    email
  end

  # TODO Conditional Emails.find_tenants/1 so that if it returns an empty array do nothing.
  def store_email(%Bamboo.Email{to: to} = email) do
    File.mkdir_p("tmp/emails/")
    # FIX_DEP
    Emails.find_tenants(to)
    |> Enum.each(&convert_email(&1, email))

    email
  end

  defp convert_email(tenant, %Bamboo.Email{
         subject: s,
         to: to,
         from: {_, from},
         html_body: html_body,
         attachments: a
       }) do
    path = "tmp/emails/#{tenant.id}.html"

    %{
      subject: s,
      to: to,
      from: from,
      tenant_id: tenant.id,
      attachments: attachments(a),
      body: plug_upload_for(path, html_body)
    }
    # FIX_DEP
    |> Emails.create_email()

    File.rm(path)
  end

  defp attachments(a) do
    Enum.map(
      a,
      fn attachment ->
        %Plug.Upload{
          filename: attachment.filename,
          content_type: attachment.content_type,
          path: attachment.path
        }
      end
    )
  end

  defp plug_upload_for(path, html) do
    File.write(path, html)
    %Plug.Upload{filename: "email.html", path: path, content_type: "text/html"}
  end
end
