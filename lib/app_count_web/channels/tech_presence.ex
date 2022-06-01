defmodule AppCountWeb.TechPresence do
  use Phoenix.Presence,
    otp_app: :app_count,
    pubsub_server: AppCount.PubSub
end
