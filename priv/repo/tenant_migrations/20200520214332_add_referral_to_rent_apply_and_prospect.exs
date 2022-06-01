defmodule AppCount.Repo.Migrations.AddReferralToRentApplyAndProspect do
  use Ecto.Migration

  def change do
    alter table(:prospects__prospects) do
      add :referral, :string, null: true
    end

    alter table(:rent_apply__rent_applications) do
      add :referral, :string, null: true
    end
  end
end
