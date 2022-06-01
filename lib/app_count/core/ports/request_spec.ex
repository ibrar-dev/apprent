defmodule AppCount.Core.Ports.RequestSpec do
  @moduledoc """
  Specify everything we need to make an http request and get a reply
  """
  defstruct url: :not_set,
            token: :not_set,
            request: :not_set,
            verb: :not_set,
            returning: :not_set,
            adapter: :not_set,
            id: :not_set,
            deps: %{}
end
