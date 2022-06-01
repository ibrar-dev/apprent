defmodule Authorize.SandboxProcessor do
  @moduledoc """
  In Dev mode, we want the ability to summon sandbox credentials.
  """

  def processor(property_id, source) do
    %AppCount.Properties.Processor{
      name: "Authorize",
      property_id: property_id,
      type: source.type,
      keys: credentials()
    }
  end

  def credentials() do
    [
      "3L39mA2sMKuu",
      "4n54w7X4Vf4Aw4M8",
      "Simon"
    ]
  end
end
