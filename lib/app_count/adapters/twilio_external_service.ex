defmodule AppCount.Adapters.TwilioExternalService do
  alias AppCount.Core.Ports.RequestSpec
  require Logger
  @one_sec_in_milliseconds 1_000

  # ref: https://hexdocs.pm/external_service/ExternalService.Gateway.html#content
  use ExternalService.Gateway,
    fuse: [
      # Tolerate 5 failures for every 1 second time window.
      strategy: {:standard, 5, @one_sec_in_milliseconds},
      # Reset the fuse 5 seconds after it is blown.
      refresh: 5_000
    ],
    # Limit to 5 calls per second.
    rate_limit: {5, :timer.seconds(1)},
    retry: [
      # Use linear backoff.
      backoff: {:linear, 100, 1},
      # Stop retrying after 5 seconds.
      expiry: 5_000
    ]

  def safe_call(%RequestSpec{adapter: :not_set}) do
    {:error, "adapter not set in RequestSpec"}
  end

  def safe_call(%RequestSpec{url: :not_set}) do
    {:error, "URL not set in RequestSpec"}
  end

  def safe_call(%RequestSpec{verb: :not_set}) do
    {:error, "Verb not set in RequestSpec"}
  end

  def safe_call(%RequestSpec{adapter: adapter} = request_spec) do
    external_call(fn ->
      case adapter.unsafe_call(request_spec) do
        {:error, reason} ->
          {:retry, reason}

        {:error, 400, "Bad Request"} ->
          Logger.error(
            "#{adapter}.safe_call => {:error, 400 Bad Request} #{inspect(request_spec)}"
          )

          {:error, "400 Bad Request"}

        {:ok, reply} ->
          {:ok, reply}

        unknown_error ->
          Logger.error(
            "#{adapter}.safe_call =>  #{inspect(unknown_error)}  #{inspect(request_spec)}"
          )

          {:error, unknown_error}
      end
    end)
  end
end
