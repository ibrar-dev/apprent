defmodule AppCount.Finance.FinanceBoundary do
  alias AppCount.Finance.AccountRepo

  def list_accounts(repo \\ AccountRepo) do
    {:ok, repo.all()}
  end

  def create_account(params, repo \\ AccountRepo) do
    repo.insert(params)
  end

  def get_account(id, repo \\ AccountRepo) do
    {:ok, repo.get_aggregate(id)}
  end
end
