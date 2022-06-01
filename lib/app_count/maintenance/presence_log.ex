defmodule AppCount.Maintenance.PresenceLog do
  use Ecto.Schema
  import Ecto.Changeset
  alias AppCount.Maintenance.PresenceLog

  schema "maintenance__presence_logs" do
    field :present, :boolean
    belongs_to :tech, Module.concat(["AppCount.Maintenance.Tech"])

    timestamps()
  end

  @doc false
  def changeset(%PresenceLog{} = presence_log, attrs) do
    presence_log
    |> cast(attrs, [:present, :tech_id])
    |> validate_required([:present, :tech_id])
  end
end
