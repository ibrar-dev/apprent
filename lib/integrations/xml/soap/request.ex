defmodule AppCount.Xml.SOAP.Request do
  alias AppCount.Core.HTTPClient

  def request(url, data, soap_options \\ []) do
    body = AppCount.Xml.to_soap(data, soap_options)

    headers = [
      {"Content-Type", "text/xml"},
      {"Content-Length", String.length(body)},
      {"SOAPAction", soap_options[:soap_action]}
    ]

    HTTPClient.post(url, body, headers,
      timeout: 50_000,
      recv_timeout: 50_000,
      hackney: [:insecure]
    )
  end
end
