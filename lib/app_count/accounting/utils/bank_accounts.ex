defmodule AppCount.Accounting.Utils.BankAccounts do
  alias AppCount.Repo
  alias AppCount.Accounting.BankAccount
  alias AppCount.Accounting.Entity
  import Ecto.Query
  import AppCount.EctoExtensions

  def list_bank_accounts() do
    from(
      a in BankAccount,
      left_join: c in assoc(a, :checks),
      left_join: p in assoc(a, :properties),
      left_join: acc in assoc(a, :account),
      select:
        map(a, [:id, :name, :bank_name, :address, :account_number, :routing_number, :account_id]),
      select_merge: %{
        max_number: max(c.number),
        properties: jsonize(p, [:id, :name]),
        property_ids: array(p.id),
        account: acc.name
      },
      group_by: [a.id, acc.id]
    )
    |> Repo.all()
  end

  def list_bank_accounts(property_id) do
    from(
      a in BankAccount,
      left_join: c in assoc(a, :checks),
      left_join: p in assoc(a, :properties),
      select: map(a, [:id, :name, :bank_name, :address, :account_number, :routing_number]),
      select_merge: %{
        max_number: max(c.number)
      },
      where: p.id == ^property_id,
      group_by: a.id
    )
    |> Repo.all()
  end

  def create_bank_account(params) do
    %BankAccount{}
    |> BankAccount.changeset(params)
    |> Repo.insert!()
    |> attach_properties(params)
  end

  def update_bank_account(id, params) do
    Repo.get(BankAccount, id)
    |> BankAccount.changeset(params)
    |> Repo.update!()
    |> attach_properties(params)
  end

  def attach_properties(account, %{"property_ids" => property_ids}) do
    from(e in Entity,
      where: e.bank_account_id == ^account.id and e.property_id not in ^property_ids
    )
    |> Repo.delete_all()

    Enum.each(
      property_ids,
      fn property_id ->
        %Entity{}
        |> Entity.changeset(%{property_id: property_id, bank_account_id: account.id})
        |> Repo.insert()
      end
    )

    {:ok, account}
  end

  def attach_properties(account, _), do: {:ok, account}

  def delete_bank_account(%AppCount.Core.ClientSchema{name: client_schema, attrs: admin}, id) do
    Repo.get(BankAccount, id, prefix: client_schema)
    |> AppCount.Admins.Utils.Actions.admin_delete(%AppCount.Core.ClientSchema{
      name: client_schema,
      attrs: admin
    })
  end

  def get_bank_account(id) do
    Repo.get(BankAccount, id)
  end
end
