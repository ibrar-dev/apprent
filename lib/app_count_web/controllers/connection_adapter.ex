defmodule AppCountWeb.ConnectionAdapter do
  @method_dict %{
    "POST" => "Created",
    "PATCH" => "Updated",
    "DELETE" => "Deleted"
  }

  @type_dict %{
    "POST" => "create",
    "PATCH" => "update",
    "DELETE" => "delete"
  }

  @excluded ["Upload"]

  def attrs(conn, desc \\ nil) do
    case readable_desc(conn) do
      nil ->
        nil

      {type, readable} ->
        data = %{
          admin_id: conn.assigns.admin.id,
          ip: get_user_ip(conn),
          params: conn.params,
          type: type,
          description: desc || readable
        }

        AppCount.Core.ClientSchema.new(conn.assigns.client_schema, data)
    end
  end

  defp get_user_ip(conn) do
    get_forwarding_header(conn) || convert_ip(conn.remote_ip)
  end

  defp get_forwarding_header(conn) do
    List.first(Plug.Conn.get_req_header(conn, "x-forwarded-for"))
  end

  defp convert_ip(ip_tuple) do
    ip_tuple
    |> Tuple.to_list()
    |> Enum.join(".")
  end

  defp readable_desc(conn) do
    router_module = Module.concat(["AppCountWeb.Router"])

    {_, _, _, {controller, _}} =
      router_module.__match_route__(conn.method, conn.path_info, conn.host)

    resource =
      "#{controller}"
      |> String.replace(~r/.*\./, "")
      |> String.replace("Controller", "")
      |> String.replace(~r/(.)([A-Z])/, "\\1 \\2")

    if resource in @excluded do
      nil
    else
      {@type_dict[conn.method], "#{@method_dict[conn.method]} a #{resource}"}
    end
  end
end
