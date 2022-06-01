defmodule Payscape.Request do
  alias Payscape.URL
  alias Payscape.Authentication
  @headers [{"Content-Type", "application/json"}]

  @spec request(String.t(), map, String.t() | nil) :: {:ok, String.t()} | {:error, map}
  def request(body, processor, path \\ nil, method \\ :post) do
    headers =
      @headers
      |> Enum.concat([
        {"Authorization", Authentication.auth_header(processor)},
        {"Content-Length", String.length(body)}
      ])

    url =
      if path do
        URL.rest_url(path)
      else
        URL.url()
      end

    HTTPoison.request(method, url, body, headers, recv_timeout: 500_000, timeout: 500_000)
    |> process_response
  end

  defp process_response({:error, error}) do
    {:error, error}
  end

  defp process_response({:ok, %HTTPoison.Response{body: body}}), do: {:ok, body}
end
