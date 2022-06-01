defmodule AppCount.Accounts.Utils.Logins do
  alias AppCount.Repo
  alias AppCount.Accounts.Login

  def create_login(params) do
    %Login{}
    |> Login.changeset(params)
    |> Repo.insert()
  end
end
