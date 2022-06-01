defmodule AppCount.Ledgers.Utils.ChargeCodes do
  alias AppCount.Core.ClientSchema
  alias AppCount.Ledgers.ChargeCodeRepo
  alias AppCount.Ledgers.ChargeCode

  def list(%ClientSchema{} = schema) do
    ChargeCodeRepo.list(schema)
  end

  def insert_charge_code(%ClientSchema{name: client_schema, attrs: params}) do
    ChargeCodeRepo.insert(params, prefix: client_schema)
  end

  def update_charge_code(%ClientSchema{name: client_schema, attrs: id}, params) do
    AppCount.Repo.get(ChargeCode, id, prefix: client_schema)
    |> ChargeCodeRepo.update(params, prefix: client_schema)
  end

  def delete_charge_code(%ClientSchema{} = schema) do
    ChargeCodeRepo.delete(schema)
  end
end
