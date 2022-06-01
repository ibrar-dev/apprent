defmodule AppCount.Yardi.ImportChargeCodeXlsx do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Accounting.Account
  alias AppCount.Ledgers.ChargeCodeRepo

  def perform_import(file_path) do
    [{:ok, tid}] = Xlsxir.multi_extract(file_path)
    do_import(tid)
    Xlsxir.close(tid)
  end

  defp do_import(tid) do
    account_map = get_account_map()

    tid
    |> Xlsxir.get_mda()
    |> Map.drop([0, 1, 2, 3, 4])
    |> Map.values()
    |> Enum.each(&import_charge_code(&1, account_map))
  end

  defp import_charge_code(charge_code_data, account_map) do
    account_id = account_map[charge_code_data[5]]

    if account_id do
      %{
        account_id: account_id,
        code: charge_code_data[2],
        name: charge_code_data[3]
      }
      |> ChargeCodeRepo.insert()
    end
  end

  defp get_account_map() do
    from(a in Account, select: {a.num, a.id})
    |> Repo.all()
    |> Enum.into(%{}, fn {num, id} -> {"#{num}", id} end)
  end
end
