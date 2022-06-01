defmodule AppCount.Adapters.PayscapeAdapter do
  @moduledoc """
  Connects to the outside world using Payscape
  Later this will be wrapped in ExternalService controls to make it more reliable.
  """

  # TODO Normalize error return values so that Authoerize and PayScape return the same things to the port
  def process_payment(amount, source, processor) do
    Payscape.process_payment(amount, source, processor)
  end
end
