defmodule AppCount.ExternalService do
  @moduledoc """
  Helper for defining an external service adapter
  This provides the boring boiler plate to keep the real adapter modules more focused
  """

  def xml_adapter do
    quote do
      unquote(adapter())

      def decode_into({:ok, %HTTPoison.Response{status_code: status_code, body: body}}, module)
          when status_code in [200, 201] do
        AppCount.Xml.Parse.parse(body)
        |> module.new
      end
    end
  end

  def json_adapter do
    quote do
      unquote(adapter())

      def headers_with_basic_auth(basic_auth_token) do
        encoded_token =
          basic_auth_token
          |> Base.encode64()

        [
          {"Content-Type", "application/x-www-form-urlencoded"},
          {"Authorization", "Basic #{encoded_token}"}
        ]
      end

      def headers_with_bearer(token) when is_binary(token) do
        [
          {"Content-Type", "application/json"},
          {"Authorization", "Bearer #{token}"}
        ]
      end

      # NO CONTENT (DELETE) See: https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/204
      def decode_into({:ok, %HTTPoison.Response{status_code: 204}}, _module) do
        {:ok, "successfully deleted"}
      end

      # CREATE
      def decode_into(
            {:ok, %HTTPoison.Response{status_code: status_code, body: body}},
            response_module
          )
          when status_code in [200, 201] do
        case Poison.decode(body, %{keys: :atoms}) do
          {:ok, jbody} ->
            response = response_module.new(jbody)

            {:ok, response}

          {:error, message} ->
            {:error, "Parse error: #{inspect(message)}"}
        end
      end

      def check_status_code({:ok, %HTTPoison.Response{status_code: status_code}}, response_module)
          when status_code in [200, 201] do
        response = %{status: status_code} |> response_module.new()

        {:ok, response}
      end

      def check_status_code(
            {:ok, %HTTPoison.Response{status_code: status_code, body: body}},
            _response_module
          )
          when status_code in 400..451 do
        {:error, "Parse error: #{inspect(body)}"}
      end

      def check_status_code(
            unexpected,
            _response_module
          ) do
        {:error, "Error: #{inspect(unexpected)}"}
      end
    end
  end

  def service do
    quote do
      @one_sec_in_milliseconds 1_000

      # ref: https://hexdocs.pm/external_service/ExternalService.Gateway.html#content
      use ExternalService.Gateway,
        fuse: [
          # Tolerate 5 failures for every 1 second time window.
          strategy: {:standard, 5, @one_sec_in_milliseconds},
          # Reset the fuse 5 seconds after it is blown.
          refresh: 5_000
        ],
        # Limit to 10 calls per second.
        rate_limit: {10, :timer.seconds(1)},
        retry: [
          # Use linear backoff.
          backoff: {:linear, 100, 1},
          # Stop retrying after 5 seconds.
          expiry: 5_000
        ]
    end
  end

  defp adapter do
    quote do
      require Logger
      def no_op, do: :ok

      def return_ok_error({:error, reason}) do
        {:error, reason}
      end

      def return_ok_error({:ok, response}) do
        {:ok, response}
      end

      def return_ok_error(other_response) do
        {:ok, other_response}
      end

      # For debugging the unsafe_calls()
      # ref https://til.hashrocket.com/posts/c4d1c06bcp-convert-httpoison-request-into-curl-command
      #
      # dump_curl(method, url, body, headers, params)
      # |> inspect(limit: :infinity, printable_limit: :infinity)
      #
      def dump_curl(method, url, body, headers, params \\ []) do
        headers = headers |> Enum.map(fn {k, v} -> "-H \"#{k}: #{v}\"" end) |> Enum.join(" ")
        body = (body && body != "" && "-d '#{body}'") || nil
        params = URI.encode_query(params || [])
        url = [url, params] |> Enum.filter(&(&1 != "")) |> Enum.join("?")

        try do
          result =
            [
              "curl -v",
              "#{method}",
              headers,
              body,
              url,
              ";"
            ]
            |> Enum.join(" ")

          result
        rescue
          error ->
            inspect(error)
        end
      end

      def decode_into({_, %HTTPoison.Response{status_code: 500, body: body}}, _response_module) do
        ~s[#{__MODULE__}.decode_into() status_code: 500 #{inspect(body)}"]
        |> Logger.error()

        {:retry, "500-Internal Server Error"}
      end

      def decode_into({_, %HTTPoison.Response{status_code: 400, body: body}}, _response_module) do
        ~s[#{__MODULE__}.decode_into() status_code: 400 #{inspect(body)}"]
        |> Logger.error()

        {:error, 400, "Bad Request"}
      end

      def decode_into({_, %HTTPoison.Response{status_code: 401, body: body}}, _response_module) do
        ~s[#{__MODULE__}.decode_into() status_code: 401 #{inspect(body)}"]
        |> Logger.error()

        {:error, 401, "Unauthorized - Bad Credentials"}
      end

      def decode_into({_, %HTTPoison.Response{status_code: 403, body: body}}, _response_module) do
        ~s[#{__MODULE__}.decode_into() status_code: 403 #{inspect(body)}"]
        |> Logger.error()

        {:error, 403, "Forbidden"}
      end

      def decode_into({_, %HTTPoison.Response{status_code: 404, body: body}}, _response_module) do
        ~s[#{__MODULE__}.decode_into() status_code: 404 #{inspect(body)}"]
        |> Logger.error()

        {:error, "404-Not Found"}
      end

      def decode_into(
            {:error, %HTTPoison.Error{id: nil, reason: reason}} = other,
            _response_module
          ) do
        ~s[#{__MODULE__} API is down: #{reason} "]
        |> Logger.error()

        other
      end

      def decode_into(
            {:error, {:retries_exhausted, %HTTPoison.Error{id: nil, reason: reason}}} = other,
            _response_module
          ) do
        ~s[#{__MODULE__} API is down: retries_exhausted. Reason: #{reason}"]
        |> Logger.error()

        other
      end

      def decode_into({:error, {:fuse_blown, service_module}} = other, _response_module) do
        Logger.error(~s[Internal error in: #{service_module}"])
        other
      end

      def decode_into({:retry, %HTTPoison.Error{reason: :checkout_failure}}, response_module) do
        Logger.error(~s[Checkout failure: #{response_module}"])
        :checkout_failure
      end
    end
  end

  defmacro __using__(which) when which in [:json_adapter, :xml_adapter, :service] do
    apply(__MODULE__, which, [])
  end
end
