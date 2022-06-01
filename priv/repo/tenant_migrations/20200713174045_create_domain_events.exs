defmodule AppCount.Repo.Migrations.CreateDomainEvents do
  use Ecto.Migration

  def change do
    create table(:core__domain_events) do
      add(:topic, :string, null: false)
      add(:name, :string, null: false)
      add(:content, :string, null: false)
      add(:source, :string, null: false)
      add(:subject_name, :string)
      add(:subject_id, :integer)
      timestamps(updated_at: false)
    end

    create(index(:core__domain_events, [:topic]))
    create(index(:core__domain_events, [:topic, :name]))
    create(index(:core__domain_events, [:subject_name, :subject_id]))
  end
end
