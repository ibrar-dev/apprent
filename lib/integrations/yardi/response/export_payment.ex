defmodule Yardi.Response.ExportPayment do
  def new({:ok, response}), do: new(response)

  def new(response) do
    response[:ImportResidentTransactions_LoginResult][:Messages][:Message]
    |> extract_content
  end

  defp extract_content(messages) when is_list(messages) do
    response =
      Enum.map(messages, & &1.content)
      |> Enum.join("\n")

    {is_error(hd(messages)), response}
  end

  defp extract_content(messages), do: {is_error(messages), messages.content}

  defp is_error(%{attributes: attrs}) do
    if attrs[:messageType] == "Error" do
      :error
    else
      :ok
    end
  end
end
