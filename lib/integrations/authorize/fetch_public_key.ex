defmodule Authorize.FetchPublicKey do
  @moduledoc """
  We programmatically fetch the public key associated with a merchant account.

  This public key is used to tokenize credit card information; then we store
  just the token, rather than the credit card itself.

  This keeps the AppRent server out of PCI scope and thus away from PCI audits.
  """
  import Authorize.Authentication
  import XmlBuilder
  import SweetXml
  alias Authorize.URL

  def fetch(processor) do
    req =
      request_body(processor)
      |> XmlBuilder.generate()

    AppCount.Core.HTTPClient.post(URL.url(), req, headers())
    |> process_response()
  end

  # Build our XML
  defp request_body(processor) do
    element(
      :getMerchantDetailsRequest,
      %{xmlns: "AnetApi/xml/v1/schema/AnetApiSchema.xsd"},
      [
        auth_node(processor)
      ]
    )
  end

  # Request headers
  defp headers() do
    [{"Content-Type", "text/xml"}]
  end

  defp process_response({:error, error}) do
    {:error, error}
  end

  defp process_response({:ok, %HTTPoison.Response{body: body}}) do
    body
    |> parse_response()
  end

  defp parse_response(body) do
    body
    |> parse(namespace_conformant: true)
    |> xmap(public_key: ~x"//getMerchantDetailsResponse/publicClientKey/text()"S)
  end
end
