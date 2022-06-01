defmodule AppCount.Accounting.Utils.Accounts do
  alias AppCount.Repo
  alias AppCount.Accounting.Account
  alias AppCount.Accounting.AccountRepo
  import Ecto.Query

  def list_accounts(%AppCount.Core.ClientSchema{name: client_schema}) do
    from(
      c in Account,
      select:
        map(c, [
          :id,
          :name,
          :is_credit,
          :is_balance,
          :is_cash,
          :is_payable,
          :num,
          :description,
          :external_id
        ]),
      order_by: [
        asc: c.num
      ]
    )
    |> Repo.all(prefix: client_schema)
  end

  def create_account(%AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    params
    |> AccountRepo.insert(prefix: client_schema)
    # this appears to be the only place where update_templates is called when accounts are created.
    # should it be in other places as well?
    # it's not clear what is going on with Agents here
    |> update_templates
  end

  def update_account(id, %AppCount.Core.ClientSchema{name: client_schema, attrs: params}) do
    Repo.get(Account, id, prefix: client_schema)
    |> AccountRepo.update(params, prefix: client_schema)
    # this appears to be the only place where update_templates is called when accounts are updated.
    # should it be in other places as well?
    # it's not clear what is going on with Agents here
    |> update_templates
  end

  def delete_account(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}, id) do
    Repo.get(Account, id, prefix: client_schema)
    |> AppCount.Admins.Utils.Actions.admin_delete(%AppCount.Core.ClientSchema{
      name: client_schema,
      attrs: admin
    })
    |> publish_account_deleted()
    # this appears to be the only place where update_templates is called when accounts are deleted.
    # should it be in other places as well?
    # it's not clear what is going on with Agents here
    |> update_templates
  end

  defp update_templates({:ok, _} = r) do
    AppCount.Accounting.update_templates()
    r
  end

  defp update_templates(e), do: e

  defp publish_account_deleted({:ok, account}) do
    AccountRepo.deleted_event(account)
    {:ok, account}
  end

  defp publish_account_deleted(result) do
    result
  end
end
