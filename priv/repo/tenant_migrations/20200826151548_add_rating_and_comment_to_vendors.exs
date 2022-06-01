defmodule AppCount.Repo.Migrations.AddRatingAndCommentToVendors do
  use Ecto.Migration

  def change do
    alter table(:vendors__vendors) do
      add(:rating, :integer)
      add(:completion_comment, :text)
    end
  end
end
