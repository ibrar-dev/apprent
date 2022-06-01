defmodule AppCount.Accounts.LockRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Accounts.Lock,
    preloads: [:admin]

  def account_lock(%AppCount.Core.ClientSchema{name: client_schema, attrs: account_id}) do
    lock_query(account_id)
    |> limit(1)
    |> Repo.one(prefix: client_schema)
  end

  def active_lock(account_id) do
    account_lock(account_id)
    |> enabled_lock()
  end

  def account_locked(account_id) do
    account_lock(account_id)
    |> case do
      nil -> false
      lock -> lock.enabled
    end
  end

  defp enabled_lock(%{enabled: false}), do: nil

  defp enabled_lock(lock), do: lock

  defp lock_query(account_id) do
    from(
      l in @schema,
      where: l.account_id == ^account_id,
      order_by: [desc: :updated_at]
    )
  end
end
