defmodule AppCount.Repo.Migrations.ApplicantsGetChecks do
  use Ecto.Migration

  def change do
    alter table(:accounting__checks) do
      add :applicant_id, references(:rent_apply__persons, on_delete: :delete_all)
    end

    drop constraint(:accounting__checks, :has_only_one_payee)
    drop constraint(:accounting__checks, :has_payee)
    create constraint(
             :accounting__checks,
             :has_one_payee,
             check: "(payee_id IS NOT NULL AND tenant_id IS NULL AND applicant_id IS NULL)
  OR (tenant_id IS NOT NULL AND payee_id IS NULL AND applicant_id IS NULL)
  OR (applicant_id IS NOT NULL AND payee_id IS NULL AND tenant_id IS NULL)"
           )
    create index(:accounting__checks, [:applicant_id])
  end
end
