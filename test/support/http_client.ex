defmodule AppCount.Support.HTTPClient do
  @agent_name :fake_http_client
  def initialize(responses, listener \\ nil) when is_list(responses) do
    Agent.start(fn -> {responses, listener} end, name: @agent_name)
  end

  def add_http_response(response, status_code \\ 200, listener \\ nil) do
    Agent.update(
    @agent_name,
      fn({responses, old_listener}) ->
        {[%{body: response, status_code: status_code} | responses], listener || old_listener}
      end
    )
  end

  def stop() do
    Agent.stop(@agent_name)
  end

  def get(url, headers \\ [], options \\ []) do
    next_response({:get, url, headers, nil, options})
  end

  def post(url, body, headers \\ [], options \\ []) do
    next_response({:post, url, headers, body, options})
  end

  def request(method, url, body \\ "", headers \\ [], options \\ []) do
    next_response({method, url, headers, body, options})
  end

  defp wrap_response(%{body: body, status_code: status_code}) do
    {:ok, %HTTPoison.Response{status_code: status_code, body: body}}
  end

  defp wrap_response(body) do
    {:ok, %HTTPoison.Response{status_code: 200, body: body}}
  end

  defp next_response({method, url, headers, body, options}) do
    Agent.get_and_update(@agent_name, fn {responses, monitor} ->
      if monitor, do: Process.send(monitor, {method, url, headers, body, options}, [:noconnect])
      next_response(responses, monitor)
    end)
  end

  defp next_response([next | rest], monitor), do: {wrap_response(next), {rest, monitor}}
  defp next_response([], _), do: raise("HTTPClient: Ran out of dummy HTTP responses")
end
