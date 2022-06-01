defmodule AppCount.Repo.Migrations.CreateMessagingTextMessages do
  use Ecto.Migration

  def change do
    create table(:messaging__text_messages) do
      add :direction, :string, null: false
      add :from_number, :string, null: false
      add :to_number, :string, null: false
      add :body, :text, null: true, default: ""
      add :media_types, :jsonb, default: "[]"
      add :media_urls, :jsonb, default: "[]"
      add :external_id, :string, null: true
      add :status, :string, null: true
      add :extra_params, :map, default: %{}

      timestamps()
    end

  end
end
