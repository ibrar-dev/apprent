defmodule AppCountWeb.Management.LayoutView do
  use AppCountWeb, :view

  def use_log_rocket(conn) do
    if AppCount.env().environment == :prod do
      ~e"""
      <script src="https://cdn.lr-ingest.io/LogRocket.min.js" crossorigin="anonymous"></script>
      <script>window.LogRocket && window.LogRocket.init('sitr2g/apprent');</script>
      <script>window.LogRocket && window.LogRocket.identify('<%= conn.assigns.admin.id %>', {name: '<%= conn.assigns.admin.name %>', email: '<%= conn.assigns.admin.email %>'});</script>
      """
    else
      ""
    end
  end
end
