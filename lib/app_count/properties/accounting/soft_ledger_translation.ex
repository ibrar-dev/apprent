defmodule AppCount.Finance.SoftLedgerTranslation do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @fields [:soft_ledger_type, :soft_ledger_underscore_id, :app_count_struct, :app_count_id]

  schema "soft_ledger__translations" do
    field :soft_ledger_type, :string
    field :soft_ledger_underscore_id, :integer
    field :app_count_struct, :string
    field :app_count_id, :integer
    timestamps()
  end

  def changeset(_schema, params) do
    %__MODULE__{}
    |> cast(params, @fields)
    |> validate_required(@fields)
  end

  def softledger_id(%__MODULE__{
        soft_ledger_type: soft_ledger_type,
        soft_ledger_underscore_id: soft_ledger_underscore_id
      }) do
    {soft_ledger_type, soft_ledger_underscore_id}
  end

  def app_count_id(%__MODULE__{
        app_count_struct: app_count_struct,
        app_count_id: app_count_id
      }) do
    {app_count_struct, app_count_id}
  end
end
