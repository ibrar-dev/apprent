defmodule Payscape.URL do
  @sandbox_url "https://xmltest.propay.com/api/propayapi.aspx"
  @live_url "https://epay.propay.com/api/propayapi.aspx"
  @sandbox_rest_url "https://xmltestapi.propay.com/"
  @live_rest_url "https://api.propay.com/"

  def url do
    case AppCount.env(:authorize_env) do
      :sandbox -> @sandbox_url
      :live -> @live_url
    end
  end

  def rest_url(path) do
    case AppCount.env(:authorize_env) do
      :sandbox -> @sandbox_rest_url <> path
      :live -> @live_rest_url <> path
    end
  end
end
