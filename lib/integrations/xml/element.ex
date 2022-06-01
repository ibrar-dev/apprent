defmodule AppCount.Xml.Element do
  import XmlBuilder
  alias AppCount.Xml.SOAP.Wrapper
  @behaviour Access

  @enforce_keys [:name]
  defstruct attributes: %{}, content: [], name: nil

  @impl Access
  def fetch(%{content: content}, _) when is_binary(content), do: :error

  def fetch(%{content: content}, key) when is_list(content) do
    case Enum.filter(content, &(&1.name == key)) do
      [] -> :error
      [item] -> {:ok, item}
      result -> {:ok, result}
    end
  end

  @impl Access
  def pop(map, key), do: Map.pop(map, key)

  @impl Access
  def get_and_update(map, key, fun) when is_map(map), do: Map.get_and_update(map, key, fun)

  def to_builder(%__MODULE__{name: name, content: content, attributes: attributes})
      when is_list(content) do
    element(name, attributes, Enum.map(content, &to_builder/1))
  end

  def to_builder(%__MODULE__{name: name, content: content, attributes: attributes}) do
    element(name, attributes, content)
  end

  def to_builder(data), do: data

  def to_xml(data) do
    to_builder(data)
    |> generate(format: :none)
  end

  def to_soap(data, soap_options) do
    Wrapper.new(soap_options)
    |> Wrapper.wrap(to_builder(data))
    |> generate(format: :none)
  end

  defimpl Inspect do
    def inspect(%{content: str, attributes: attrs, name: name}, _)
        when is_binary(str) or is_integer(str) or is_float(str) do
      attr_string = Enum.map(attrs, fn {k, v} -> "#{k}=#{v}" end)
      ~s/<#{[name | attr_string] |> Enum.join(" ")}>#{str}<\/#{name}>/
    end

    def inspect(%{content: nil, attributes: attrs, name: name}, _) do
      attr_string = Enum.map(attrs, fn {k, v} -> "#{k}=#{v}" end)
      ~s/<#{[name | attr_string] |> Enum.join(" ")}\/>/
    end

    def inspect(%{content: content, attributes: attrs, name: name}, _) do
      attr_string = Enum.map(attrs, fn {k, v} -> "#{k}=#{v}" end)

      ~s/<#{[name | attr_string] |> Enum.join(" ")}>#{
        Enum.map(content, &inspect/1) |> Enum.join("")
      }<\/#{name}>/
    end
  end
end
