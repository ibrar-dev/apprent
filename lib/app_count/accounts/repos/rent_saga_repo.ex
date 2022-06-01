defmodule AppCount.Accounts.RentSagaRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Core.RentSaga,
    preloads: [
      :payment_source,
      :processor,
      :credit_card_processor,
      :bank_account_processor,
      account: [:payment_sources]
    ]

  alias AppCount.Core.ClientSchema

  def get_by_transaction_id(transaction_id) do
    from(
      o in @schema,
      where: o.transaction_id == ^transaction_id,
      preload: ^@preloads,
      limit: 1
    )
    |> Repo.one()
  end

  def load_account(%ClientSchema{name: client_schema, attrs: account_id}) do
    account =
      AppCount.Repo.get(AppCount.Accounts.Account, account_id, prefix: client_schema)
      |> Repo.preload(:tenant, prefix: client_schema)
      |> Repo.preload(:payment_sources, prefix: client_schema)

    case account do
      %AppCount.Accounts.Account{} -> {:ok, account}
      _ -> {:error, "Account not Found"}
    end
  end

  def load_latest(%ClientSchema{name: client_schema, attrs: account_id}) do
    from(session in @schema,
      where: session.account_id == ^account_id,
      order_by: [desc: session.started_at],
      limit: 1
    )
    |> Repo.one(prefix: client_schema)
  end

  def create_session(account, params) do
    %{account_id: account.id, started_at: DateTime.utc_now()}
    |> Map.merge(params)
    |> insert()
  end

  def update(schema, params) when is_map(params) do
    schema
    |> @schema.update_changeset(params)
    |> Repo.update()
  end

  def update!(schema, params) when is_map(params) do
    schema
    |> @schema.update_changeset(params)
    |> Repo.update!()
  end
end
