defmodule AppCountWeb.Users.PropertyView do
  use AppCountWeb.Users, :view

  def icon("facebook"), do: "facebook-f"
  def icon(type), do: type
end
