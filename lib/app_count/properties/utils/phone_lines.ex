defmodule AppCount.Properties.Utils.PhoneLines do
  alias AppCount.Repo
  alias AppCount.Properties.PhoneLine
  import Ecto.Query

  def list_phone_lines(property_id) do
    from(
      p in PhoneLine,
      where: p.property_id == ^property_id,
      select: map(p, [:id, :number])
    )
    |> Repo.all()
  end

  def create_phone_line(params) do
    %PhoneLine{}
    |> PhoneLine.changeset(params)
    |> Repo.insert()
  end

  def update_phone_line(id, params) do
    Repo.get(PhoneLine, id)
    |> PhoneLine.changeset(params)
    |> Repo.update()
  end

  def delete_phone_line(id) do
    Repo.get(PhoneLine, id)
    |> Repo.delete()
  end
end
