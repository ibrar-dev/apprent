defmodule Authorize.PublicCredentials do
  alias Authorize.URL
  alias Authorize.FetchPublicKey
  alias AppCount.Properties.Processor

  def credentials(%Processor{name: "Authorize"} = processor) do
    case FetchPublicKey.fetch(processor) do
      %{public_key: public_key} ->
        url = URL.token_url()
        [login_id | _] = processor.keys

        %{
          processor: "Authorize",
          url: url,
          login_id: login_id,
          public_key: public_key
        }

      {:error, %{reason: :timeout}} ->
        %{error: "Server timeout"}

      {:error, %{reason: reason}} when is_binary(reason) ->
        %{error: reason}

      {:error, reason} when is_binary(reason) ->
        %{error: reason}
    end
  end

  def credentials(_) do
    %{}
  end
end
