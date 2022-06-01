alias AppCount.Accounting
alias AppCount.Accounts
alias AppCount.Admins
alias AppCount.Jobs
alias AppCount.Leases
alias AppCount.Maintenance
alias AppCount.Materials
alias AppCount.Messaging
alias AppCount.Properties
alias AppCount.Prospects
alias AppCount.RentApply
alias AppCount.Repo
alias AppCount.Rewards
alias AppCount.Socials
alias AppCount.Tenants
alias AppCount.Units
alias AppCount.Vendors
alias AppCount.Exports
alias AppCount.Leasing
import Ecto.Query

defmodule Helpers do
  def copy(term) do
    text =
      if is_binary(term) do
        term
      else
        inspect(term, limit: :infinity, pretty: true)
      end

    port = Port.open({:spawn, "pbcopy"}, [])
    true = Port.command(port, text)
    true = Port.close(port)

    :ok
  end
end

super_admin = %{roles: MapSet.new(["Super Admin"])}
admin = %{roles: MapSet.new(["Admin"])}
