defmodule AppCount.Repo.Migrations.AddUploadErrorField do
  use Ecto.Migration

  def up do
    execute "DROP VIEW #{prefix()}.data__upload_urls;"
    alter table(:data__uploads) do
      add :is_error, :boolean, null: false, default: false
    end
    execute """
    CREATE VIEW #{prefix()}.data__upload_urls AS
      SELECT id,
       coalesce(array_position(ARRAY[is_error, is_loading, is_public], 't'), 0) || ':' || (uuid || '/' || filename) as url
    FROM #{prefix()}.data__uploads u;
    """
  end

  def down do
    execute "DROP VIEW #{prefix()}.data__upload_urls;"
    alter table(:data__uploads) do
      remove :is_error
    end
    execute """
    CREATE VIEW #{prefix()}.data__upload_urls AS
      SELECT id,
       (CASE WHEN is_loading = 't' THEN 'loa:' ELSE (CASE WHEN is_public = 't' THEN 'pub:' ELSE 'pri:' END) END) ||
       (uuid || '/' || filename) as url
    FROM #{prefix()}.data__uploads u;
    """
  end
end
