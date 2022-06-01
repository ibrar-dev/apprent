defmodule AppCountWeb.Users.PackageView do
  use AppCountWeb.Users, :view

  def filter_packages(packages, filter) do
    packages
    |> Enum.filter(&(&1.status == filter))
  end

  def color_for_status("Pending"), do: "warning"
  def color_for_status("Hold"), do: "warning"
  def color_for_status("Delivered"), do: "success"
  def color_for_status("Undeliverable"), do: "danger"
  def color_for_status("Returned"), do: "danger"
  def color_for_status(_), do: "warning"

  def icon_for_status("Pending"), do: "far fa-clock"
  def icon_for_status("Hold"), do: "far fa-hand-paper"
  def icon_for_status("Delivered"), do: "far fa-thumbs-up"
  def icon_for_status("Undeliverable"), do: "fas fa-exclamation-triangle"
  def icon_for_status("Returned"), do: "fas fa-undo"
  def icon_for_status(_), do: "fas fa-question"
end
