defmodule AppCount.ObserverSupervisor do
  @moduledoc """
  These gen_servers act as observers of other system activity.
  They then take action based on that activity
  """
  use Supervisor

  def start_link(_opts \\ []) do
    AppCount.GenserverLogger.starting(__MODULE__)
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      AppCount.Maintenance.OrderObserver,
      AppCount.Core.PaymentObserver,
      AppCount.Core.TenantObserver,
      AppCount.Finance.FinanceRecorder
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
