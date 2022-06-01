defmodule AppCount.UrlHelper do
  # :dev, :test, :prod

  @environment Mix.env()

  def admin_url() do
    admin_url(@environment)
  end

  def admin_url(:dev) do
    "http://administration.appcount.test:4002"
  end

  def admin_url(:prod) do
    "https://administration.apprent.com"
  end

  def admin_url(:test) do
    "http://administration.appcount.test:4002"
  end
end
