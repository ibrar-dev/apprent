defmodule AppCount.Reports.Property.BoxScore.Applicants do
  use AppCount.Decimal
  import Ecto.Query
  import AppCount.EctoExtensions
  alias AppCount.Repo
  alias AppCount.Ledgers.Payment
  alias AppCount.RentApply.RentApplication

  # DATE | Amount | Applicant | Transaction-ID | Description | Account Number - i assume is last 4 of card used if card was used
  ## GET PAYMENTS AND THEN GET APPLICANTS
  def get_payments(property_id, start_date, end_date) do
    from(
      p in Payment,
      left_join: ra in subquery(applicant_query(property_id)),
      on: ra.id == p.application_id,
      where:
        p.property_id == ^property_id and
          (p.description in ["Application Fee", "Administration Fee"] or
             not is_nil(p.application_id)),
      where: fragment("? between ? and ?", p.inserted_at, ^start_date, ^end_date),
      select: %{
        id: p.id,
        amount: p.amount,
        persons: ra.persons,
        #        payer: fragment("CASE WHEN ? IS NULL THEN array(?)[1] ELSE ? END", p.payer, ra.persons, p.payer),
        payer: p.payer,
        date: p.inserted_at,
        transaction_id: p.transaction_id,
        response: p.response,
        tenant_id: p.tenant_id,
        application_id: p.application_id,
        description: p.description,
        expected_move_in: ra.expected_move_in,
        floor_plan: ra.floor_plan
      },
      group_by: [p.id, ra.id, ra.persons, ra.expected_move_in, ra.floor_plan],
      order_by: [desc: :inserted_at]
    )
    |> Repo.all()

    #    |> group_data
  end

  defp applicant_query(property_id) do
    from(
      a in RentApplication,
      where: a.property_id == ^property_id,
      join: p in assoc(a, :persons),
      join: mi in assoc(a, :move_in),
      left_join: fp in assoc(mi, :floor_plan),
      select: %{
        id: a.id,
        persons: jsonize(p, [:id, :full_name]),
        expected_move_in: mi.expected_move_in,
        floor_plan: fp.name
      },
      group_by: [a.id, mi.expected_move_in, fp.name]
    )
  end

  # unused ?
  # defp group_data(payments) do
  #   sum = %{payments: payments, total: 0.00, count: 0}

  #   payments
  #   |> Enum.reduce(sum, fn p, acc ->
  #     %{payments: acc.payments, total: acc.total + p.amount, count: acc.count + 1}
  #   end)
  # end
end
