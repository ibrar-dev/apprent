defmodule AppCount.Repo.Migrations.DropPaymentImageField do
  use Ecto.Migration

  def change do
    alter table(:accounting__payments) do
      remove :image
    end
  end
end
