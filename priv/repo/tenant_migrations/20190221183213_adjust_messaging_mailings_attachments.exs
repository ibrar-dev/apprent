defmodule AppCount.Repo.Migrations.AdjustMessagingMailingsAttachments do
  use Ecto.Migration

  def change do
    alter table(:messaging__mailings) do
      remove :attachments, :jsonb
      add :attachments, {:array, :string}, default: "{}", null: false
    end
  end
end
