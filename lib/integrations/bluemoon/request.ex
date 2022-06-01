defmodule BlueMoon.Request do
  alias BlueMoon.Credentials
  alias BlueMoon.Utils
  @endpoint "https://www.bluemoonforms.com/services/lease.php"
  @headers {"Content-Type", "text/xml charset=UTF-8"}

  def make_request(%Credentials{} = credentials, type, request_body, xpath) do
    case BlueMoon.Auth.session_id(credentials) do
      {:ok, session} -> make_request(session, type, request_body, xpath)
      {:error, :bad_auth} -> {:error, "Authentication values rejected"}
    end
  end

  def make_request(session, type, request_body, xpath) do
    Utils.session_wrapper(session, type, request_body)
    |> perform_request(type)
    |> case do
      {body, 200} ->
        {:ok, xpath(body, xpath)}

      {error_xml, 500} ->
        {:error, xpath(error_xml, SweetXml.sigil_x("//faultstring/text()", 'S'))}

      {:error, e} ->
        {:error, e}

      _ ->
        {:error, "Unknown error"}
    end
  end

  def perform_request(req, function) do
    AppCount.Core.HTTPClient.post(
      @endpoint,
      req,
      [{"SOAPAction", "#{@endpoint}#{function}"}, @headers]
    )
    |> case do
      {:ok, %{body: body, status_code: code}} -> {body, code}
      {:error, e} -> {:error, e}
    end
  end

  defp xpath(body, {path, :transform}), do: Utils.xml_to_map(body, path)
  defp xpath(body, {path, options}), do: SweetXml.xpath(body, path, options)
  defp xpath(body, path), do: SweetXml.xpath(body, path)
end
