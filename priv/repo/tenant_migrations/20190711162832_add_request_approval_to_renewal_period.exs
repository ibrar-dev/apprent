defmodule AppCount.Repo.Migrations.AddRequestApprovalToRenewalPeriod do
  use Ecto.Migration

  def change do
    alter table(:leases__renewal_periods) do
      add :approval_request, :naive_datetime, null: true
      add :notes, :jsonb, default: "[]"
    end

    alter table(:leases__custom_packages) do
      add :notes, :jsonb, default: "[]"
    end

    alter table(:leases__renewal_packages) do
      add :notes, :jsonb, default: "[]"
    end
  end
end
