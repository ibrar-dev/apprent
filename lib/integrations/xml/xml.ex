defmodule AppCount.Xml do
  import XmlBuilder
  alias AppCount.Xml.Element
  alias AppCount.Xml.SOAP.Wrapper

  def to_builder(%Element{name: name, content: content, attributes: attributes})
      when is_list(content) do
    element(name, attributes, Enum.map(content, &to_builder/1))
  end

  def to_builder(%Element{name: name, content: content, attributes: attributes}) do
    element(name, attributes, content)
  end

  def to_builder(data), do: data

  @spec to_xml(%Element{}) :: String.t()
  def to_xml(data) do
    to_builder(data)
    |> generate(format: :none)
  end

  @spec to_soap(%Element{}, list) :: String.t()
  def to_soap(data, soap_options \\ []) do
    Wrapper.new(soap_options)
    |> Wrapper.wrap(to_builder(data))
    |> generate(format: :none)
  end
end
