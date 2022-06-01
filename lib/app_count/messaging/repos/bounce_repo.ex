defmodule AppCount.Messaging.BounceRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Messaging.Bounce

  def create_from_ses(params) do
    %{"bounce" => decoded} = decode_ses_message(params)

    Enum.each(decoded["bouncedRecipients"], fn recipient ->
      insert(%{target: recipient["emailAddress"]})
    end)
  end

  defp decode_ses_message(params) do
    {:ok, decoded} = Poison.decode(params)
    {:ok, message} = Poison.decode(decoded["Message"])
    message
  end

  def exists?(email) when is_binary(email) do
    query = from table in @schema, where: ilike(table.target, ^email)
    Repo.exists?(query)
  end

  def exists?(_) do
    false
  end

  def clear_bounces(nil) do
    {0, nil}
  end

  # Returns {7, nil} where 7 is how many were deleted
  def clear_bounces(email_address) do
    query = from table in @schema, where: ilike(table.target, ^email_address)

    Repo.delete_all(query)
  end
end
