defmodule AppCount.Repo.Migrations.AddGatewayXMLToScreening do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__screenings) do
      add :gateway_xml, :text
    end

    alter table(:properties__persons) do
      add :gateway_xml, :text
    end
  end
end
