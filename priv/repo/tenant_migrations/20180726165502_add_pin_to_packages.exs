defmodule AppCount.Repo.Migrations.AddPinToPackages do
  use Ecto.Migration

  def change do
     alter table(:properties__packages) do
        add :pin, :string, default: "0000", null: false
        add :reason, :string, null: true
     end
  end
end
