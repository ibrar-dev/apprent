defmodule AppCount.Support.Adapters.CreditCardAuthorizeSandbox do
  @moduledoc """
  Provides fake data during testing
  """

  def process_payment(amount, source, _discarded_processor) do
    sandbox_processor = %AppCount.Properties.Processor{
      name: "Authorize",
      property_id: 000,
      type: "cc",
      keys: credentials()
    }

    Authorize.process_payment(amount, source, sandbox_processor)
  end

  # move to config/dev.exs
  def credentials() do
    [
      "3L39mA2sMKuu",
      "4n54w7X4Vf4Aw4M8",
      "Simon"
    ]
  end
end
