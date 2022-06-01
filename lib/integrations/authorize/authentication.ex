defmodule Authorize.Authentication do
  @moduledoc """
  Build authentication node for access -- all requests (other than tokenization)
  require access with a private API key
  """
  import XmlBuilder

  def auth_node(%{keys: [api_key, transaction_key, _]}) do
    element(:merchantAuthentication, [
      element(:name, api_key),
      element(:transactionKey, transaction_key)
    ])
  end
end
