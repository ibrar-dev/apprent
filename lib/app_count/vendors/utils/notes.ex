defmodule AppCount.Vendors.Utils.Notes do
  alias AppCount.Repo
  alias AppCount.Vendors.Note

  def create_note(params) do
    %Note{}
    |> Note.changeset(params)
    |> Repo.insert!()
  end

  def delete_note(id) do
    Repo.get(Note, id)
    |> Repo.delete()
  end
end
