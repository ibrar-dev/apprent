defmodule AppCount.Core.HTTPClient do
  @client Application.compile_env(:app_count, :http_client, HTTPoison)

  def get(url, headers \\ [], options \\ []) do
    @client.get(url, headers, options)
  end

  def post(url, body, headers \\ [], options \\ []) do
    @client.post(url, body, headers, options)
  end

  def request(method, url, body \\ "", headers \\ [], options \\ []) do
    @client.request(method, url, body, headers, options)
  end
end
