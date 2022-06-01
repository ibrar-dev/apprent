defmodule AppCountAuth.OpenController do
  @moduledoc """
    Authorizer for controllers that for whatever reason need no
    authorization logic or for which authorization has not yet been implemented.

    Will return `true` for every authorization question
  """
  use AppCountAuth, :request
end
