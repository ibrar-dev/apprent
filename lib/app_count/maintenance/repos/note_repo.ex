defmodule AppCount.Maintenance.NoteRepo do
  @preloads [:tenant, :admin, :tech, :attachment, :attachment_url]

  use AppCount.Core.GenericRepo,
    schema: AppCount.Maintenance.Note,
    preloads: @preloads

  alias AppCount.Maintenance.Note

  def get_notes(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: order_id
        },
        :private
      ) do
    from(
      n in Note,
      where: n.order_id == ^order_id,
      preload: ^@preloads
    )
    |> Repo.all(prefix: client_schema)
  end

  # To be called by the resident, will only return notes that are viewable by the resident
  def get_notes(
        %AppCount.Core.ClientSchema{
          name: client_schema,
          attrs: order_id
        },
        :public
      ) do
    from(
      n in Note,
      where: n.order_id == ^order_id,
      where: n.visible_to_resident,
      preload: ^@preloads
    )
    |> Repo.all(prefix: client_schema)
  end
end
