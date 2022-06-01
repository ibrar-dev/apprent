defmodule AppCount.Settings.Utils.Damages do
  alias AppCount.Repo
  alias AppCount.Settings.Damage
  import Ecto.Query

  def list_damages() do
    from(
      d in Damage,
      join: a in assoc(d, :account),
      select: map(d, [:id, :name, :account_id]),
      select_merge: %{account: a.name},
      order_by: [
        asc: d.name
      ]
    )
    |> Repo.all()
  end

  def create_damage(params) do
    %Damage{}
    |> Damage.changeset(params)
    |> Repo.insert()
  end

  def update_damage(id, params) do
    Repo.get(Damage, id)
    |> Damage.changeset(params)
    |> Repo.update()
  end

  def delete_damage(id) do
    Repo.get(Damage, id)
    |> Repo.delete()
  end
end
