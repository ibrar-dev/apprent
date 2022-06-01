defmodule AppCount.Repo.Migrations.AdjustRentLeaseFields do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__leases) do
      remove :bug_inspected
      remove :bug_awareness_level
      add :bug_inspection, :integer
      add :bug_infestaion, :integer
      add :bug_disclosure, :text
      remove :fitness_card_number
      add :fitness_card_numbers, {:array, :string}, default: "{}"
    end
  end
end
