defmodule AppCount.Repo.Migrations.AddLocalKeysToProcessorsProperties do
  use Ecto.Migration

  def change do
    alter table("properties__processors") do
      add(:local_keys, {:array, :text}, default: "{}", null: false)
    end
  end
end
