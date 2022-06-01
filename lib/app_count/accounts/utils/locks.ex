defmodule AppCount.Accounts.Utils.Locks do
  alias AppCount.Repo
  alias AppCount.Accounts.Lock
  alias AppCount.Accounts.Account
  import Ecto.Query

  def create_lock(params) do
    %Lock{}
    |> Lock.changeset(params)
    |> Repo.insert()
  end

  def update_lock(id, params) do
    Repo.get(Lock, id)
    |> Lock.changeset(params)
    |> Repo.update()
  end

  def delete_lock(id) do
    Repo.get(Lock, id)
    |> Repo.delete()
  end

  def lock_account(tenant_id, reason) do
    from(a in Account, where: a.tenant_id == ^tenant_id, select: a.id)
    |> Repo.one()
    |> case do
      nil -> nil
      account_id -> create_lock(%{account_id: account_id, reason: reason})
    end
  end
end
