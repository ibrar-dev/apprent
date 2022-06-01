defmodule AppCountWeb.BounceController do
  use AppCountWeb, :public_controller
  require Logger

  # To verify with AWS we need to log the first request and then update it.
  def create(conn, params) do
    Logger.info(inspect(params))
    bounce_repo_boundary(conn).create_from_ses(params.text)
    json(conn, %{})
  end
end
