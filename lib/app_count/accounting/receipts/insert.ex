defmodule AppCount.Accounting.Receipts.Insert do
  def do_insert(receipts) do
    AppCount.Repo.insert_all(AppCount.Accounting.Receipt, ts(receipts))
  end

  def ts(receipts) do
    now =
      AppCount.current_time()
      |> DateTime.to_naive()
      |> NaiveDateTime.truncate(:second)

    Enum.map(receipts, &Map.merge(&1, %{inserted_at: now, updated_at: now}))
  end
end
