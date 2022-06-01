defmodule AppCount.Accounting.Utils.Registers do
  alias AppCount.Repo
  alias AppCount.Accounting.Register

  def create_register(params) do
    %Register{}
    |> Register.changeset(params)
    |> Repo.insert()
  end

  def update_register(id, params) do
    Repo.get(Register, id)
    |> Register.changeset(params)
    |> Repo.update()
  end

  def delete_register(id) do
    Repo.get(Register, id)
    |> Repo.delete()
  end
end
