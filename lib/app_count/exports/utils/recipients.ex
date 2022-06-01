defmodule AppCount.Exports.Utils.Recipients do
  alias AppCount.Repo
  alias AppCount.Exports.Recipient
  import Ecto.Query

  def list_recipients(admin_id) do
    from(
      r in Recipient,
      where: r.admin_id == ^admin_id,
      select: map(r, [:id, :name, :email])
    )
    |> Repo.all()
  end

  def insert_recipient(params) do
    %Recipient{}
    |> Recipient.changeset(params)
    |> Repo.insert()
  end

  def update_recipient(id, params) do
    Repo.get(Recipient, id)
    |> Recipient.changeset(params)
    |> Repo.update()
  end

  def delete_recipient(id) do
    Repo.get(Recipient, id)
    |> Repo.delete()
  end
end
