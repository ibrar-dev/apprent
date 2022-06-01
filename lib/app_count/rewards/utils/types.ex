defmodule AppCount.Rewards.Utils.Types do
  alias AppCount.Repo
  alias AppCount.Rewards.Type
  import Ecto.Query

  @default_types [
    "Signup",
    "Zero Balance Bonus",
    "Payment",
    "Prepaid Rent",
    "Autopay Payment",
    "Work Order Created",
    "Completed Survey",
    "Manual Adjustment"
  ]

  def list_types() do
    from(
      t in Type,
      select: map(t, [:id, :name, :icon, :active, :points, :monthly_max]),
      order_by: [
        asc: t.name
      ]
    )
    |> Repo.all()
  end

  def create_type(params) do
    %Type{}
    |> Type.changeset(params)
    |> Repo.insert()
  end

  def update_type(id, params) do
    Repo.get(Type, id)
    |> Type.changeset(params)
    |> Repo.update()
  end

  def delete_type(id) do
    Repo.get(Type, id)
    |> Repo.delete()
  end

  def create_default_types do
    now =
      DateTime.utc_now()
      |> DateTime.to_naive()
      |> NaiveDateTime.truncate(:second)

    params =
      @default_types
      |> Enum.map(&%{name: &1, inserted_at: now, updated_at: now})

    Repo.insert_all(Type, params, on_conflict: :nothing)
  end
end
