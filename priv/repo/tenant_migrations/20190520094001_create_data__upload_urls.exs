defmodule AppCount.Repo.Migrations.CreateDataUploadUrls do
  use Ecto.Migration

  def up do
    execute """
    CREATE VIEW #{prefix()}.data__upload_urls AS
      SELECT id,
       (CASE WHEN is_loading = 't' THEN 'loa:' ELSE (CASE WHEN is_public = 't' THEN 'pub:' ELSE 'pri:' END) END) ||
       (uuid || '/' || filename) as url
    FROM #{prefix()}.data__uploads u;
    """
  end

  def down do
    execute "DROP VIEW #{prefix()}.data__upload_urls;"
  end
end
