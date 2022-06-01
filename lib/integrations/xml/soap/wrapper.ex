defmodule AppCount.Xml.SOAP.Wrapper do
  import XmlBuilder

  defstruct xsi: "http://www.w3.org/2001/XMLSchema-instance",
            xsd: "http://www.w3.org/2001/XMLSchema",
            soap: "http://schemas.xmlsoap.org/soap/envelope/"

  def new(options \\ []) do
    mapped = for {a, v} <- options, into: %{}, do: {a, v}
    struct(__MODULE__, mapped)
  end

  def wrap(%__MODULE__{} = wrapper, body) do
    element(
      :"soap:Envelope",
      %{"xmlns:xsi" => wrapper.xsi, "xmlns:xsd" => wrapper.xsd, "xmlns:soap" => wrapper.soap},
      [
        element(:"soap:Body", [body])
      ]
    )
  end
end
