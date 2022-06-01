defmodule AppCount.Repo.Migrations.ChangeGatewayXmlToArray do
  use Ecto.Migration

  def change do
    alter table(:leases__screenings) do
      add :xml_data, {:array, :text}, default: "{}", null: false
    end
  end
end
