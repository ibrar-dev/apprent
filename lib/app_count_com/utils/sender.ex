defmodule AppCountCom.Mailer.Sender do
  @adapters %{
    prod: AppCountCom.Mailer.SES,
    staging: AppCountCom.Mailer.Dev,
    test: AppCountCom.Mailer.Test,
    dev: AppCountCom.Mailer.Dev
  }
  alias AppCount.Messaging.BounceRepo
  @deliver_module Module.concat(["AppCountCom.Utils.Storage"])

  def send_email(_template, nil, _subject, _vars), do: {:error, "Cannot send without to address"}

  # If unable to send right now only return nil.
  # Maybe should be updated to send an error tuple if unable to send?
  def send_email(template, to_address, subject, vars) do
    if can_send?(to_address) do
      mailer = @adapters[AppCount.Config.env()]

      # Bamboo 2.0 now returns an  :ok-tuple.
      result =
        AppCountCom.Mailer.Email.send_email(template, to_address, subject, vars)
        |> @deliver_module.async_store_email()
        |> mailer.deliver_now()

      case result do
        {:ok, bamboo_email} -> bamboo_email
        {:error, {_status, _to_address, message}} -> {:error, message}
        _ -> {:error, "Could not send"}
      end
    else
      nil
    end
  end

  def can_send?({_, email}), do: can_send?(email)

  def can_send?(email, repo \\ BounceRepo) do
    email_on_bounce_list = repo.exists?(email)
    well_formed?(email) and !email_on_bounce_list
  end

  # At minimum, 2 characters, @, 1 more character, dot, 2 or more characters
  defp well_formed?(email) when is_binary(email) do
    String.match?(email, ~r(\A.{2,}@.{1,}\..{2,}\z))
  end

  # Not well formed if nil or otherwise non-string
  defp well_formed?(_email) do
    false
  end
end
