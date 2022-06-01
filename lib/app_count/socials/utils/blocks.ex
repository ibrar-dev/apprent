defmodule AppCount.Socials.Utils.Blocks do
  alias AppCount.Repo
  alias AppCount.Socials.Block

  def create_block(params) do
    %Block{}
    |> Block.changeset(params)
    |> Repo.insert()
  end

  def delete_block(params) do
    Repo.get_by!(Block, tenant_id: params.tenant_id, blockee_id: params.blockee_id)
    |> Repo.delete()
  end
end
