defmodule TenantSafe.HandlePostback do
  import SweetXml

  @spec handle(String.t()) :: map()
  def handle(body) do
    body
    |> parse(namespace_conformant: true)
    |> xmap(
      ref: ~x"//ReferenceId/text()"S,
      order_id: ~x"//OrderId/text()"S,
      status: ~x"//ScreeningStatus/OrderStatus/text()"S,
      decision: ~x"//ScreeningStatus/OrderDecision/text()"S,
      url: ~x"//InternetWebAddress/text()"S,
      gateway_xml:
        ~x"//GatewayXml"e
        |> transform_by(&extract_gateway_xml/1)
    )
    |> strip_blank_xml
  end

  defp strip_blank_xml(%{gateway_xml: nil} = p), do: Map.delete(p, :gateway_xml)
  defp strip_blank_xml(p), do: p

  defp extract_gateway_xml(nil), do: nil

  defp extract_gateway_xml(xml_node) do
    [xml_node]
    |> :xmerl.export(:xmerl_xml)
    |> List.flatten()
    |> to_string
  end
end
