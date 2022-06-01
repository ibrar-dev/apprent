defmodule AppCount.Repo.Migrations.AddTermsAndConditionsToRentalApplications do
  use Ecto.Migration

  def change do
    alter table(:rent_apply__rent_applications) do
      add :terms_and_conditions, :text, default: ""
    end
  end
end
