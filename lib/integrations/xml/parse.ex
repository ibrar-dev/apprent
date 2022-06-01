defmodule AppCount.Xml.Parse do
  alias AppCount.Xml.Element

  def parse(xml) do
    try do
      xml
      |> :erlang.binary_to_list()
      |> :xmerl_scan.string(hook_fun: &parse_node/2, acc_fun: &accumulator/3)
      |> unpack_soap
    catch
      :exit, {:fatal, {error, _, _, _}} -> {:error, "Invalid XML: #{error}"}
    end
  end

  def parse_node({:xmlElement, name, _, _, _, _, _, attributes, content, _, _, _}, global_state) do
    {%Element{name: name, content: content, attributes: parse_attrs(attributes)}, global_state}
  end

  def parse_node({:xmlText, _, _, _, text, :text}, global_state) do
    {String.trim("#{text}"), global_state}
  end

  def accumulator("", acc, global_state), do: {acc, global_state}

  def accumulator(%Element{content: [str]} = parsed, acc, global_state) when is_binary(str) do
    {[%{parsed | content: str} | acc], global_state}
  end

  def accumulator(%Element{content: []} = parsed, acc, global_state) do
    {[%{parsed | content: nil} | acc], global_state}
  end

  def accumulator(parsed, acc, global_state) do
    {[parsed | acc], global_state}
  end

  def parse_attrs(attrs) do
    Enum.into(
      attrs,
      %{},
      fn {:xmlAttribute, name, _, _, _, _, _, _, value, _} ->
        {name, "#{value}"}
      end
    )
  end

  def unpack_soap(
        {%Element{
           name: :"soap:Envelope",
           content: [%Element{name: :"soap:Body", content: [body]}]
         }, _}
      ),
      do: {:ok, body}

  def unpack_soap({result, _}), do: {:ok, result}
end
