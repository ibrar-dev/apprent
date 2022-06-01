defmodule Authorize.URL do
  @sandbox_url "https://apitest.authorize.net/xml/v1/request.api"
  @live_url "https://api.authorize.net/xml/v1/request.api"

  @sandbox_accept_js "https://jstest.authorize.net/v1/Accept.js"
  @live_accept_js "https://js.authorize.net/v1/Accept.js"

  def url do
    case environment() do
      :sandbox -> @sandbox_url
      :live -> @live_url
    end
  end

  def token_url do
    case environment() do
      :sandbox -> @sandbox_accept_js
      :live -> @live_accept_js
    end
  end

  def environment do
    AppCount.env(:authorize_env)
  end
end
