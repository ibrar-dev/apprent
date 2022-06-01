defmodule AppCountWeb.ApplicationFormView do
  use AppCountWeb, :view

  def use_log_rocket(property) do
    if AppCount.env().environment == :prod do
      ~e"""
      <script src="https://cdn.lr-ingest.io/LogRocket.min.js" crossorigin="anonymous"></script>
      <script>window.LogRocket && window.LogRocket.init('sitr2g/apprent');</script>
      <script>window.LogRocket && window.LogRocket.identify('<%= :rand.uniform(99999) %>', {name: '<%= property.name %>'});</script>
      """
    else
      ""
    end
  end
end
