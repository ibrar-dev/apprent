defmodule AppCount.Tasks.Workers.PollForLeaseSignatures do
  alias AppCount.Repo
  alias AppCount.Leases.Lease
  alias AppCount.Leases.Form
  import Ecto.Query
  use AppCount.Tasks.Worker, "Poll for Bluemoon lease signatures"

  @impl AppCount.Tasks.Worker
  def perform(schema \\ "dasmen") do
    from(
      f in Form,
      join: a in assoc(f, :application),
      where: a.status == "lease_sent" or not is_nil(f.lease_id),
      where: f.signed == false,
      select: f.id
    )
    |> Repo.all(prefix: schema)
    |> Enum.each(&AppCount.Leases.get_signature_status/1)

    from(l in Lease, where: not is_nil(l.pending_bluemoon_lease_id))
    |> Repo.all(prefix: schema)
    |> Enum.each(&AppCount.Leases.get_signature_status/1)
  end
end
