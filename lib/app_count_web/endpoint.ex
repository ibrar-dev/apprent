defmodule AppCountWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :app_count

  @session_options [
    store: :cookie,
    key: "_app_count_web_key",
    signing_salt: "CqKekY59"
  ]

  socket("/ws/tech", AppCountWeb.TechSocket, websocket: true, longpoll: false)
  socket("/ws/admin", AppCountWeb.AdminSocket, websocket: true, longpoll: false)
  socket("/ws/user", AppCountWeb.Users.UserSocket, websocket: true, longpoll: false)
  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phoenix.digest
  # when deploying your static files in production.
  plug(
    Plug.Static,
    at: "/",
    from: :app_count,
    gzip: false,
    only: ~w(css fonts images js media favicon.ico modules robots.txt helpers)
    #    headers: %{"Access-Control-Allow-Origin" => "*"}
  )

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
  end

  plug Phoenix.LiveDashboard.RequestLogger,
    param_key: "request_logger",
    cookie_key: "request_logger"

  plug(Plug.RequestId)
  plug Plug.Logger
  plug AppCountWeb.ExtractIPPlug

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json, :xml, :text],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library(),
    xml_decoder: :xmerl_scan,
    length: 100_000_000
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug(
    Plug.Session,
    @session_options
  )

  plug CORSPlug, headers: CORSPlug.defaults()[:headers] ++ ["x-admin-token"]

  plug(AppCountWeb.Router)
end
