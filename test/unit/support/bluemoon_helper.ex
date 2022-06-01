defmodule AppCount.BlueMoonHelper do
  @sources Path.expand("../resources/BlueMoon", __DIR__)

  def mock_bluemoon_responses(responses) do
    session_response = File.read!(@sources <> "/CreateSessionIn.xml")

    Enum.flat_map(responses, fn r ->
      [session_response, File.read!(@sources <> "/" <> r <> ".xml")]
    end)
    |> AppCount.Support.HTTPClient.initialize()
  end

  def mock_bluemoon_responses(responses, :no_session) do
    ["CreateSessionIn" | responses]
    |> Enum.map(&File.read!(@sources <> "/" <> &1 <> ".xml"))
    |> AppCount.Support.HTTPClient.initialize()
  end
end
