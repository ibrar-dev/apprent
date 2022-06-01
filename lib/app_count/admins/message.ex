defmodule AppCount.Admins.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "admins__messages" do
    field :category, :string
    field :content, :string
    belongs_to :admin, AppCount.Admins.Admin

    timestamps()
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [:content, :category, :admin_id])
    |> validate_required([:content, :category, :admin_id])
  end
end
