defmodule BlueMoon.Utils do
  import SweetXml
  import XmlBuilder
  import Ecto.Query
  alias AppCount.Repo

  def session_wrapper(session, function, body \\ []) do
    element(
      "ns1:#{function}",
      [element(:SessionId, session), body]
    )
    |> soap_wrap
    |> generate(format: :none)
  end

  def soap_wrap(body) do
    element(
      "soap:Envelope",
      %{
        "xmlns:soap" => "http://schemas.xmlsoap.org/soap/envelope/",
        "xmlns:ns1" => "https://www.bluemoonforms.com/services/lease.php"
      },
      [element("soap:Body", [body])]
    )
  end

  @spec params_to_xml([{String.t(), String.t()}]) :: [{String.t(), nil, String.t()}]
  def params_to_xml(params) do
    Enum.map(params, fn {name, value} ->
      element(name, nil, value)
    end)
  end

  @spec date_formatter(String.t() | %DateTime{} | %Date{} | nil) :: String.t()
  def date_formatter(date) when is_binary(date), do: date

  def date_formatter(date) do
    (date || AppCount.current_time())
    |> Timex.format!("%m/%d/%Y", :strftime)
  end

  def xml_to_map(xml, xpath) do
    xpath(xml, xpath)
    |> process_element(%{})
  end

  def get_unit_number(unit_id) do
    from(
      p in AppCount.Properties.Unit,
      where: p.id == ^unit_id,
      select: p.number
    )
    |> Repo.one()
  end

  def write_to_file(item, name), do: File.write(name, Poison.encode!(item))

  defp process_children([{:xmlText, _, _, _, _, _} = text_node]), do: extract_text(text_node)
  defp process_children(nodes), do: Enum.reduce(nodes, %{}, &process_element/2)

  defp process_element(list, map) when is_list(list),
    do: Enum.map(list, &process_element(&1, map))

  defp process_element({:xmlText, _, _, _, _, _}, map), do: map
  defp process_element({:xmlElement, _, _, _, _, _, _, _, [], _, _, _}, map), do: map

  defp process_element({:xmlElement, node_name, _, _, _, _, _, _, children, _, _, _}, map) do
    Map.put(map, node_name, process_children(children))
  end

  defp extract_text({:xmlText, _, _, _, text, :text}) when hd(text) != 10,
    do: String.trim("#{text}")
end
