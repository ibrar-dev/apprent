defmodule AppCount.Repo.Migrations.AddChargeRefToChecks do
  use Ecto.Migration

  def change do
    alter table(:accounting__checks) do
      add :charge_id, references(:accounting__charges, on_delete: :delete_all)
    end

    create constraint(:accounting__checks, :tenant_checks_have_charge, check: "tenant_id IS NULL OR charge_id IS NOT NULL")
    create constraint(:accounting__checks, :invoice_checks_have_no_charge, check: "payee_id IS NULL OR charge_id IS NULL")
    create index(:accounting__checks, [:charge_id])
  end
end
