defmodule Plug.Parsers.TEXT do
  @behaviour Plug.Parsers
  import Plug.Conn

  def init(opts), do: opts

  def parse(conn, _, "plain", _headers, opts) do
    conn
    |> read_body(opts)
    |> decode()
  end

  def parse(conn, _type, _subtype, _headers, _opts) do
    {:next, conn}
  end

  defp decode({:ok, body, conn}), do: {:ok, %{text: body}, conn}

  # we might want to use this part but hold off for now
  #  defp decode({:ok, body, conn}, decoder) do
  #    case decoder.string(String.to_charlist(body)) do
  #      {parsed, []} ->
  #        {:ok, %{xml: parsed}, conn}
  #      error ->
  #        raise "Malformed XML #{error}"
  #    end
  #  rescue
  #    e -> raise Plug.Parsers.ParseError, exception: e
  #  end
end
