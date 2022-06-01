defmodule AppCountWeb.ExtractIPPlug do
  import Plug.Conn

  def init(default), do: default

  def call(conn, _default) do
    ip = get_forwarding_header(conn) || convert_ip(conn.remote_ip)
    assign(conn, :formatted_ip_address, ip)
  end

  defp get_forwarding_header(conn) do
    List.first(Plug.Conn.get_req_header(conn, "x-forwarded-for"))
  end

  # In: {127, 0, 0, 1}
  # Out: "127.0.0.1"
  defp convert_ip(ip_tuple) do
    ip_tuple
    |> Tuple.to_list()
    |> Enum.join(".")
  end
end
