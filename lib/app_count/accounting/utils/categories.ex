defmodule AppCount.Accounting.Utils.Categories do
  import Ecto.Query
  alias AppCount.Repo
  alias AppCount.Accounting.Account
  alias AppCount.Accounting.Category

  def create_category(params) do
    %Category{}
    |> Category.changeset(params)
    |> Repo.insert()
    |> update_templates
  end

  def update_category(id, params) do
    Repo.get(Category, id)
    |> Category.changeset(params)
    |> Repo.update()
    |> update_templates
  end

  def delete_category(id) do
    Repo.get(Category, id)
    |> Repo.delete()
    |> update_templates
  end

  ## Pass in a number and it will spit out the depth level of the account or category, to be used for indentation and whatnot.
  def get_depth(num) do
    max =
      from(
        a in Category,
        where: a.num < ^num,
        limit: 1,
        order_by: [
          desc: a.num
        ]
      )
      |> Repo.one()
      |> category_max

    from(
      a in Category,
      where: fragment("? BETWEEN ? AND ?", ^num, a.num, ^max),
      select: count(a.id)
    )
    |> Repo.one()
  end

  def account_tree(opts) do
    categories =
      from(
        c in Category,
        select: map(c, [:id, :name, :num, :is_balance]),
        select_merge: %{
          is_credit: c.is_balance,
          is_cash: c.is_balance,
          is_payable: c.is_balance,
          description: "",
          source_id: 0,
          external_id: "",
          type: "category",
          max: c.max,
          total_only: c.total_only,
          in_approvals: c.in_approvals
        },
        group_by: c.id
      )

    accounts =
      from(
        a in Account,
        select:
          map(a, [
            :id,
            :name,
            :num,
            :is_balance,
            :is_credit,
            :is_cash,
            :is_payable,
            :description,
            :source_id,
            :external_id
          ]),
        select_merge: %{
          type: "account",
          max: 00_000_000,
          total_only: type(^false, :boolean),
          in_approvals: type(^false, :boolean)
        },
        where: not is_nil(a.num),
        group_by: a.id
      )

    union = from(c in subquery(categories), union: ^subquery(accounts))

    ordered =
      from(
        a in subquery(union),
        order_by: [
          asc: a.num
        ]
      )

    Enum.reduce(
      opts,
      ordered,
      fn {k, v}, query ->
        query
        |> where([a], field(a, ^k) == ^v)
      end
    )
    |> Repo.all()
    |> add_in_totals
    |> Enum.map(&Map.merge(&1, %{depth: get_depth(&1.num)}))
  end

  def add_in_totals(list) do
    categories = Enum.filter(list, &(&1.type == "category"))

    Enum.reduce(
      categories,
      list,
      fn c, acc ->
        max = category_max(c)

        params = %{
          description: "",
          id: nil,
          is_balance: c.is_balance,
          is_cash: c.is_cash,
          is_credit: c.is_credit,
          is_payable: c.is_payable,
          num: max,
          max: max,
          header: c.num,
          name: "Total #{c.name}",
          total_only: false,
          type: "total"
        }

        acc ++ [params]
      end
    )
    |> Enum.sort_by(& &1.num)
  end

  def category_max(%{max: nil, num: num}) do
    "#{num}"
    |> String.trim_trailing("0")
    |> String.pad_trailing(8, "9")
    |> String.to_integer()
  end

  def category_max(nil), do: category_max(%{max: nil, num: nil})
  def category_max(%{max: max}), do: max

  def category_num_from_max(num) do
    case Repo.get_by(Category, max: num) do
      nil ->
        "#{num}"
        |> String.trim_trailing("9")
        |> String.pad_trailing(8, "0")
        |> String.to_integer()

      c ->
        c.num
    end
  end

  def get_accounts(%{id: id} = res, list) do
    cat = Repo.get(Category, id)

    ids =
      from(
        a in Account,
        where: fragment("? BETWEEN ? AND ?", a.num, ^cat.min, ^cat.max),
        where: a.id not in ^list,
        select: a.id,
        order_by: [
          asc: :num
        ]
      )
      |> Repo.all()

    result = Map.merge(res, %{accounts: ids})
    {result, ids}
  end

  def get_account_ids(min, max) do
    from(
      a in Account,
      where: fragment("? BETWEEN ? AND ?", a.num, ^min, ^max),
      select: a.id
    )
    |> Repo.all()
  end

  defp update_templates({:ok, _} = r) do
    AppCount.Accounting.update_templates()
    r
  end

  defp update_templates(e), do: e
end
