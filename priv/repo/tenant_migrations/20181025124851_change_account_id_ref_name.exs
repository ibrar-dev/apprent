defmodule AppCount.Repo.Migrations.ChangeAccountIdRefName do
  use Ecto.Migration

  def change do
    rename table(:rewards__awards), :account_id, to: :tenant_id
  end
end
