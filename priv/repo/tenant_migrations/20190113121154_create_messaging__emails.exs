defmodule AppCount.Repo.Migrations.CreateMessagingEmails do
  use Ecto.Migration

  def change do
    create table(:messaging__emails) do
      add :subject, :string, null: false
      add :body, :string, null: false
      add :to, :string, null: false
      add :from, :string, null: false
      add :attachments, {:array, :string}, default: "{}", null: false
      add :tenant_id, references(:properties__tenants, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:messaging__emails, [:tenant_id])
  end
end
