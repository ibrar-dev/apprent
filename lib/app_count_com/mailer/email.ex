defmodule AppCountCom.Mailer.Email do
  import Bamboo.Email

  def email_domain do
    AppCount.env(:home_url)
    |> String.replace(~r/https?:\/\//, "")
    |> String.replace(~r/:.*/, "")
  end

  def email_from do
    {"AppRent Admin", "admin@#{email_domain()}"}
  end

  def email_views(key) do
    %{
      :property => Module.concat(["AppCountCom.PropertyView"]),
      :admin => Module.concat(["AppCountCom.AdminView"]),
      nil => Module.concat(["AppCountCom.PropertyView"])
    }
    |> Map.fetch!(key)
  end

  def send_email(template, to_address, subject, vars) do
    new_email()
    |> to(to_address)
    |> from(email_from())
    |> subject(subject)
    |> put_attachments(vars[:attachments])
    |> render("#{template}.html", vars)
  end

  def render(email, template, assigns) do
    email_view_module = email_views(assigns[:layout])
    Bamboo.Phoenix.render_email(email_view_module, email, template, assigns)
  end

  defp put_attachments(email, nil), do: email

  defp put_attachments(email, attachments) do
    Enum.reduce(
      attachments,
      email,
      fn %{path: p} = a, e ->
        put_attachment(e, Bamboo.Attachment.new(p, Map.to_list(a)))
      end
    )
  end
end
