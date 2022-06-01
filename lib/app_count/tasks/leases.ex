defmodule AppCount.Tasks.Leases do
  alias AppCount.Repo
  alias AppCount.Leases.Lease
  alias AppCount.Leases.Form
  import Ecto.Query

  @spec add_move_in_dates() :: :ok
  def add_move_in_dates do
    today =
      AppCount.current_time()
      |> Timex.beginning_of_day()

    from(
      l in Lease,
      where: is_nil(l.actual_move_in),
      where: l.start_date <= ^today,
      update: [
        set: [
          actual_move_in: l.start_date
        ]
      ]
    )
    |> Repo.update_all([])
  end

  @spec poll_for_lease_signatures() :: :ok
  def poll_for_lease_signatures() do
    from(
      f in Form,
      join: a in assoc(f, :application),
      where: a.status == "lease_sent" or not is_nil(f.lease_id),
      where: f.signed == false,
      select: f.id
    )
    |> Repo.all()
    |> Enum.each(&AppCount.Leases.get_signature_status/1)

    from(l in Lease, where: not is_nil(l.pending_bluemoon_lease_id))
    |> Repo.all()
    |> Enum.each(&AppCount.Leases.get_signature_status/1)
  end
end
