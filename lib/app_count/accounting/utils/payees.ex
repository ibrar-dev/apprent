defmodule AppCount.Accounting.Utils.Payees do
  alias AppCount.Repo
  alias AppCount.Accounting.Payee
  import Ecto.Query
  import AppCount.EctoExtensions

  def list_payees(:meta) do
    from(
      p in Payee,
      where: p.approved,
      select: map(p, [:id, :name, :street, :city, :state, :zip, :phone, :email, :due_period]),
      order_by: [asc: :name]
    )
    |> Repo.all()
  end

  def list_payees() do
    from(
      p in Payee,
      left_join: i in assoc(p, :invoices),
      select:
        map(p, [
          :id,
          :name,
          :street,
          :city,
          :state,
          :zip,
          :phone,
          :email,
          :tax_form,
          :tax_id,
          :consolidate_checks,
          :due_period,
          :approved
        ]),
      select_merge: %{
        invoices: jsonize(i, [:id, :number, :post_month, :date])
      },
      group_by: p.id
    )
    |> Repo.all()
  end

  def create_payee(params) do
    %Payee{}
    |> Payee.changeset(params)
    |> Repo.insert()
  end

  def update_payee(id, params) do
    Repo.get(Payee, id)
    |> Payee.changeset(params)
    |> Repo.update()
  end

  def delete_payee(id) do
    Repo.get(Payee, id)
    |> Repo.delete()
  end

  def get_payee(id) do
    Repo.get(Payee, id)
  end
end
