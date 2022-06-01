defmodule AppCount.Ledgers.ChargeCodeRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Ledgers.ChargeCode,
    preloads: [:account]

  def list(%AppCount.Core.ClientSchema{name: client_schema}) do
    from(
      c in @schema,
      left_join: a in assoc(c, :account),
      select: %{
        id: c.id,
        code: c.code,
        name: c.name,
        account_id: c.account_id,
        account_name: a.name,
        account_num: a.num
      }
    )
    |> Repo.all(prefix: client_schema)
  end
end
