defmodule AppCountWeb.Token do
  #  OLD: @salt "salty salty salts passwords"
  #  OLD: @salt "some dumb salt this is!"
  # from AppCountWeb.API.SignaturesController
  @salt "d552nb!x$mdYg20LM"

  @endpoint Module.concat(["AppCountWeb.Endpoint"])
  @token_module Module.concat(["Phoenix.Token"])

  # 3 days of inactivity should log out.
  # The token is also used in an email link sent to admins in AppCount.Approvals,
  # Previously it was set to expire in 30 minutes, but after discussions with operations
  # We are ok moving it to also expire in 3 days.
  # If this decision ever changes we will need to create a separate token for the above scenario.
  # DA 02-01-2021
  @max_age 259_200

  # AppCountWeb.Token.token(params)
  def token(params) do
    @token_module.sign(@endpoint, @salt, params)
  end

  # AppCountWeb.Token.verify(token)
  def verify(token) do
    @token_module.verify(@endpoint, @salt, token, max_age: @max_age)
  end
end
