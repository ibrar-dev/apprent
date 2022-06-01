defmodule AppCount.Adapters.SoftLedgerExternalService do
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
    {:error, "adapter not set"}
  end

  def safe_call(%RequestSpec{url: :not_set}) do
    {:error, "URL not set"}
  end

  def safe_call(%RequestSpec{verb: :not_set}) do
    {:error, "Verb not set"}
  end

  def safe_call(%RequestSpec{returning: :not_set}) do
    {:error, "Returning not set"}
  end

  def safe_call(%RequestSpec{adapter: adapter} = request_spec) do
    external_call(fn ->
      case adapter.unsafe_call(request_spec) do
        {:error, reason} ->
          "#{adapter}.safe_call got => {:error, #{inspect(reason)}}"
          |> Logger.error()

          {:retry, reason}

        {:error, 400, "Bad Request"} ->
          "#{adapter}.safe_call got => {:error, 400 Bad Request}"
          |> Logger.error()

          {:error, "400 Bad Request"}

        {:ok, reply} ->
          {:ok, reply}

        unknown_error ->
          "#{adapter}.safe_call got =>  #{inspect(unknown_error)}"
          |> Logger.error()

          {:error, unknown_error}
      end
    end)
  end
end
