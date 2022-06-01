defmodule AppCount.RentApply.Utils.Ledgers do
  import Ecto.Query
  alias AppCount.RentApply.RentApplication
  alias AppCount.RentApply.Person
  alias AppCount.Repo

  def get_application_ledger(application_id) do
    persons =
      from(
        p in Person,
        where: p.status == "Lease Holder",
        where: p.application_id == ^application_id,
        select: map(p, [:id, :full_name])
      )
      |> Repo.all()

    payments =
      from(
        a in RentApplication,
        join: pr in assoc(a, :property),
        left_join: p in assoc(a, :payments),
        where: a.id == ^application_id,
        select:
          map(
            p,
            [
              :id,
              :amount,
              :description,
              :post_month,
              :transaction_id,
              :memo,
              :status,
              :source,
              :refund_date,
              :edits,
              :status
            ]
          ),
        select_merge: %{
          date: type(p.inserted_at, :date),
          property_id: pr.id
        },
        order_by: [
          asc: p.inserted_at
        ]
      )
      |> Repo.all()

    %{transactions: payments, applicants: persons}
  end
end
