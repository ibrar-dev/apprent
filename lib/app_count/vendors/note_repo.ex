defmodule AppCount.Vendors.NoteRepo do
  @preloads [:tech, :admin, :tenant]

  use AppCount.Core.GenericRepo,
    schema: AppCount.Vendors.Note,
    preloads: @preloads

  alias AppCount.Vendors.Note

  def get_notes(order_id) do
    from(
      n in Note,
      where: n.order_id == ^order_id,
      preload: ^@preloads
    )
    |> Repo.all()
  end
end
