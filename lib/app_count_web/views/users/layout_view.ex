defmodule AppCountWeb.Users.LayoutView do
  use AppCountWeb.Users, :view
  import AppCount, only: :macros

  @icons %{
    error: "exclamation-circle",
    info: "info",
    success: "thumbs-up"
  }

  @classes %{
    error: "danger",
    info: "info",
    success: "primary"
  }

  def flash_icon(type) do
    @icons[type]
  end

  def flash_class(type) do
    @classes[type]
  end

  def use_log_rocket(conn) do
    if AppCount.env().environment == :prod do
      ~e"""
      <script src="https://cdn.lr-ingest.io/LogRocket.min.js" crossorigin="anonymous"></script>
      <script>window.LogRocket && window.LogRocket.init('sitr2g/apprent');</script>
      <script>window.LogRocket && window.LogRocket.identify('<%= conn.assigns.user.id %>', {name: '<%= conn.assigns.user.last_name %>'});</script>
      """
    else
      ""
    end
  end
end
