defmodule AppCount.Adapters.AuthorizeAdapter do
  @moduledoc """
  Connects to the outside world using Authorize
  Later this will be wrapped in ExternalService controls to make it more reliable.
  """

  @doc """
  + amount - decimal/float in USD
  + source - AppCount.Accounts.PaymentSource%{}
  + processor - Authorize processor

  returns {:ok, result} or {:error, %{reason: "some msg"}}
  """
  def process_payment(amount, source, processor) do
    Authorize.process_payment(amount, source, processor)
  end
end
