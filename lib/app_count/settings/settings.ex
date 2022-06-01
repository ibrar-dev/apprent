defmodule AppCount.Settings do
  alias AppCount.Settings.Utils.Banks
  alias AppCount.Settings.Utils.Damages
  alias AppCount.Settings.Utils.MoveOutReasons

  def create_bank(params), do: Banks.create_bank(params)
  def list_banks(), do: Banks.list_banks()
  def update_bank(id, params), do: Banks.update_bank(id, params)
  def delete_bank(admin, id), do: Banks.delete_bank(admin, id)
  def bank_name(routing), do: Banks.bank_name(routing)

  def create_damage(params), do: Damages.create_damage(params)
  def list_damages(), do: Damages.list_damages()
  def update_damage(id, params), do: Damages.update_damage(id, params)
  def delete_damage(id), do: Damages.delete_damage(id)

  def create_move_out_reason(params), do: MoveOutReasons.create_move_out_reason(params)
  def list_move_out_reasons(), do: MoveOutReasons.list_move_out_reasons()
  def update_move_out_reason(id, params), do: MoveOutReasons.update_move_out_reason(id, params)
  def delete_move_out_reason(id), do: MoveOutReasons.delete_move_out_reason(id)
end
