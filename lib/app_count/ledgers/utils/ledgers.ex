# defmodule AppCount.Ledgers.Utils.Ledgers do
#  alias AppCount.Ledgers.CustomerLedger
#  alias AppCount.Ledgers.Charge
#  alias AppCount.Ledgers.Payment
#  alias AppCount.Repo
#  import AppCount.EctoExtensions
#  import Ecto.Query
#
#  def full_ledger(customer_ledger_id) do
#    from(
#      ledger in CustomerLedger,
#      left_join: p in assoc(ledger, :payments),
#      where: ledger.id == ^customer_ledger_id
#    )
#  end
#
#  def charge_query(customer_ledger_id) do
#    from(
#      charge in Charge,
#      where: charge.customer_ledger_id == ^customer_ledger_id,
#      select: jsonize(charge, [:id, :amount, :status, :description])
#    )
#  end
# end
