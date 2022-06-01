defmodule Expo.ServerSdk do
  @expo_server_url "https://exp.host/--/api/v2/push/send"
  @headers [{"Content-Type", "application/json"}]

  def send_message(message) do
    data = build_message(message)
    HTTPoison.post(@expo_server_url, data, @headers)
  end

  defp build_message(message) do
    '{
      "to": "#{message.token}",
      "title": "#{message.title}",
      "body": "#{message.body}"
     }'
  end
end
