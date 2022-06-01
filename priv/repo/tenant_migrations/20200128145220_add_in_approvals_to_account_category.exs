defmodule AppCount.Repo.Migrations.AddInApprovalsToAccountCategory do
  use Ecto.Migration

  def change do
    alter table(:accounting__categories) do
      add :in_approvals, :boolean, default: false
    end
  end
end
