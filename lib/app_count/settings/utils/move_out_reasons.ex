defmodule AppCount.Settings.Utils.MoveOutReasons do
  alias AppCount.Repo
  alias AppCount.Settings.MoveOutReason
  import Ecto.Query

  def list_move_out_reasons() do
    from(
      m in MoveOutReason,
      select: map(m, [:id, :name]),
      order_by: [
        asc: m.name
      ]
    )
    |> Repo.all()
  end

  # UNTESTED
  def create_move_out_reason(params) do
    %MoveOutReason{}
    |> MoveOutReason.changeset(params)
    |> Repo.insert()
  end

  # UNTESTED
  def update_move_out_reason(id, params) do
    Repo.get(MoveOutReason, id)
    |> MoveOutReason.changeset(params)
    |> Repo.update()
  end

  # UNTESTED
  def delete_move_out_reason(id) do
    Repo.get(MoveOutReason, id)
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.no_assoc_constraint(:leases)
    |> Repo.delete()
  end
end
