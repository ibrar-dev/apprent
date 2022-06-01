defmodule BlueMoon.Auth do
  import SweetXml
  import XmlBuilder
  alias BlueMoon.Request
  alias BlueMoon.Utils
  alias BlueMoon.Credentials

  @spec session_id(%Credentials{}) :: {:ok, String.t()} | {:error, :bad_auth}
  def session_id(%Credentials{serial: serial, user: user, password: password}) do
    body =
      element(
        "ns1:CreateSession",
        [element(:SerialNumber, serial), element(:UserId, user), element(:Password, password)]
      )
      |> Utils.soap_wrap()
      |> generate()

    case Request.perform_request(body, "CreateSessionIn") do
      {body, 200} ->
        {:ok, xpath(body, ~x"//ns1:CreateSessionResponse/CreateSessionResult/text()"S)}

      _ ->
        {:error, :bad_auth}
    end
  end
end
