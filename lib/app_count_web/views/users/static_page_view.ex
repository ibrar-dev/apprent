defmodule AppCountWeb.Users.StaticPageView do
  use AppCountWeb.Users, :view

  def accept_js_url() do
    if AppCount.env().environment == :prod do
      "https://js.authorize.net/v1/Accept.js"
    else
      "https://jstest.authorize.net/v1/Accept.js"
    end
  end
end
