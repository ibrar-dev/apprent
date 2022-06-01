defmodule AppCount.Exports.Reconciliation do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Accounting.ReconciliationPosting

  def get_report(posting_id) do
    posting =
      from(
        p in ReconciliationPosting,
        left_join: u in assoc(p, :document_url),
        join: bank in assoc(p, :bank_account),
        select:
          map(
            p,
            [
              :id,
              :start_date,
              :admin,
              :is_posted,
              :bank_account_id,
              :total_payments,
              :total_deposits,
              :start_date,
              :end_date
            ]
          ),
        select_merge: %{
          document_url: u.url,
          bank_name: bank.name
        },
        where: p.id == ^posting_id
      )
      |> Repo.one()

    HTTPoison.start()
    {:ok, %HTTPoison.Response{status_code: 200, body: body}} = HTTPoison.get(posting.document_url)
    {:ok, params} = Jason.decode(body)

    %{"other" => other, "deposits" => deposits, "payments" => payments} =
      Enum.reduce(
        params,
        %{"other" => 0, "deposits" => 0, "payments" => 0},
        fn x, acc ->
          {amount, _} = Float.parse(x["amount"])

          %{
            "other" =>
              if Enum.member?(
                   ["journal_income", "journal_expense", "nsf_payment", "payment_wo_batch"],
                   x["type"]
                 ) do
                acc["other"] + amount
              else
                acc["other"]
              end,
            "deposits" =>
              if Enum.member?(["batch", "payment_wo_batch"], x["type"]) do
                acc["deposits"] + amount
              else
                acc["deposits"]
              end,
            "payments" =>
              if x["type"] == "check" do
                acc["payments"] + amount
              else
                acc["payments"]
              end
          }
        end
      )

    # FIX_DEPS
    Phoenix.View.render_to_string(
      AppCountWeb.Exports.ReconciliationView,
      "index.html",
      %{
        posting: posting,
        reconciliations: params,
        other: other,
        deposits: deposits,
        payments: payments
      }
    )
    |> PdfGenerator.generate_binary()
  end
end
