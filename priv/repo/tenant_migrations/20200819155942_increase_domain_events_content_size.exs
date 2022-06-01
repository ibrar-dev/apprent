defmodule AppCount.Repo.Migrations.IncreaseDomainEventsContentSize do
  use Ecto.Migration

  def change do
    alter table("core__domain_events") do
      modify :content, :text, from: :string
    end
  end
end
