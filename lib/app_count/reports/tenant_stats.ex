defmodule AppCount.Reports.TenantStats do
  import Ecto.Query
  alias AppCount.Ledgers.Payment
  alias AppCount.Repo

  def stats(tenant_id) do
    payment_stats = average_payment_info(tenant_id)

    %{
      payments: payment_stats
    }
  end

  defp average_payment_info(tenant_id) do
    from(
      p in Payment,
      where: p.tenant_id == ^tenant_id,
      select: %{
        id: p.id,
        amount: p.amount,
        payment_date: p.inserted_at
      }
    )
    |> Repo.all()
    |> get_payment_stats()
  end

  defp get_payment_stats(payments) do
    avg_pmt_date = avg_pmt_date(payments)
    avg_pmt_amount = avg_pmt_amount(payments)

    %{
      avg_pmt_date: avg_pmt_date,
      avg_pmt_amount: avg_pmt_amount
    }
  end

  defp avg_pmt_date(payments) do
    payments
    |> Enum.map(&Timex.format!(&1.payment_date, "{D}"))
    |> AppCount.math_mode()
  end

  defp avg_pmt_amount(payments) do
    payments
    |> Enum.map(& &1.amount)
    |> AppCount.math_mode()
  end
end
