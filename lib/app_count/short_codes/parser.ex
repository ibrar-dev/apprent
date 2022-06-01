defmodule AppCount.ShortCodes.Parser do
  def parse_html(html, func) do
    {:ok, document} = Floki.parse_document(html)

    document
    |> parse_nodes(func)
    |> Floki.raw_html()
  end

  defp parse_nodes(nodes, func) when is_list(nodes), do: Enum.map(nodes, &process_node(&1, func))
  defp parse_nodes(single_node, func), do: process_node(single_node, func)

  defp process_node({"a", attrs, content}, func) do
    if Enum.any?(attrs, &({"class", "wysiwyg-mention"} == &1)) do
      {_, code} = Enum.find(attrs, &find_code/1)
      {"span", [], Enum.map(content, &replace_code(code, &1, func))}
    else
      {"a", attrs, Enum.map(content, &process_node(&1, func))}
    end
  end

  defp process_node({tag, attrs, content}, func) do
    {tag, attrs, Enum.map(content, &process_node(&1, func))}
  end

  defp process_node(b, _), do: b

  defp replace_code(code, content, func) when is_binary(content), do: "#{func.(code)}"

  defp replace_code(code, {tag, attrs, content}, func),
    do: {tag, attrs, Enum.map(content, &replace_code(code, &1, func))}

  defp find_code({"data-value", code}), do: code
  defp find_code(_), do: false
end
