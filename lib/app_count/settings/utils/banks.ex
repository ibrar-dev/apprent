defmodule AppCount.Settings.Utils.Banks do
  alias AppCount.Repo
  alias AppCount.Settings.Bank
  import Ecto.Query

  def list_banks() do
    from(
      b in Bank,
      select: map(b, [:id, :name, :routing]),
      order_by: [
        asc: b.routing
      ]
    )
    |> Repo.all()
  end

  def bank_name(routing) do
    from(b in Bank, where: b.routing == ^routing, select: b.name)
    |> Repo.one()
  end

  def create_bank(params) do
    %Bank{}
    |> Bank.changeset(params)
    |> Repo.insert()
  end

  def update_bank(id, params) do
    Repo.get(Bank, id)
    |> Bank.changeset(params)
    |> Repo.update()
  end

  def delete_bank(admin, id) do
    Repo.get(Bank, id)
    |> AppCount.Admins.Utils.Actions.admin_delete(admin)
  end
end
