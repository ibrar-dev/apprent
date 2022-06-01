defmodule AppCountWeb.API.V1.TwilioController do
  use AppCountWeb, :controller
  alias AppCount.Twilio.Messaging
  alias AppCount.Messaging.TextMessageRepo

  # TODO case after create, if fails reply to sender with failure message?
  # Get clarification from OPS that this should indeed happen.
  def create(conn, params) do
    Messaging.new_incoming(params)
    |> Map.from_struct()
    |> TextMessageRepo.create()

    json(conn, %{})
  end
end
