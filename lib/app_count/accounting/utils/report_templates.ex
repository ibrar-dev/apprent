defmodule AppCount.Accounting.Utils.ReportTemplates do
  alias AppCount.Repo
  alias AppCount.Accounting
  alias AppCount.Accounting.ReportTemplate
  alias AppCount.Accounting.Category
  alias AppCount.Accounting.Account
  import Ecto.Query

  @spec list_report_templates() :: [map]
  def list_report_templates do
    from(t in ReportTemplate, select: map(t, [:id, :groups, :name, :is_balance]))
    |> Repo.all()
  end

  @spec create_report_template(map) :: {:ok, %ReportTemplate{}} | {:error, Ecto.Changeset.t()}
  def create_report_template(params) do
    %ReportTemplate{}
    |> ReportTemplate.changeset(params)
    |> Repo.insert()
  end

  @spec update_report_template(integer, map) ::
          {:ok, %ReportTemplate{}} | {:error, Ecto.Changeset.t()}
  def update_report_template(id, params) do
    Repo.get(ReportTemplate, id)
    |> ReportTemplate.changeset(params)
    |> Repo.update()
  end

  @spec delete_report_template(integer) :: {:ok, %ReportTemplate{}} | {:error, Ecto.Changeset.t()}
  def delete_report_template(id) do
    Repo.get(ReportTemplate, id)
    |> Repo.delete()
  end

  @spec balance_template() :: map
  def balance_template() do
    %{
      name: "Balance Sheet",
      is_balance: true,
      groups:
        Accounting.account_tree(is_balance: true)
        |> groups
    }
  end

  @spec income_template() :: map
  def income_template() do
    %{
      name: "Income Statement",
      is_balance: false,
      groups:
        Accounting.account_tree(is_balance: false)
        |> groups
    }
  end

  @spec init_templates() :: {:ok, term}
  def init_templates() do
    Agent.start(fn -> %{balance: balance_template(), income: income_template()} end,
      name: :report_templates
    )
  end

  @spec update_templates() :: {:ok, term}
  def update_templates() do
    Agent.update(:report_templates, fn _ ->
      %{balance: balance_template(), income: income_template()}
    end)
  end

  @spec get_template(atom) :: map
  def get_template(name), do: Agent.get(:report_templates, & &1[name])

  defp groups(account_tree) do
    totals = Enum.reduce(account_tree, %{}, &collect_totals(&1, account_tree, &2))

    account_tree
    |> Enum.filter(&(&1.type != "total"))
    |> Enum.sort(&(sort_num(&1) < sort_num(&2)))
    |> process_tree_item({0, 99_999_999, totals}, [])
    |> elem(0)
  end

  defp process_tree_item(
         [%{type: "category", num: num, total_only: false} = c | rest],
         {min, max, totals},
         groups
       )
       when num > min and num < max do
    max = Accounting.category_max(c)

    {match, second} =
      Enum.split_with(
        rest,
        fn r ->
          (!r.total_only and r.num <= max) or (r.total_only and Accounting.category_max(r) <= max)
        end
      )

    {accounts, remainder} = collect_accounts(match, [], totals)
    {sub_groups, _remainder} = process_tree_item(remainder, {num, max, totals}, [])

    grouped =
      groups ++
        [
          %{
            "name" => c.name,
            "type" => "list",
            "groups" => sub_groups,
            "accounts" => accounts,
            "total_only" => false
          }
        ]

    process_tree_item(second, {0, 99_999_999, totals}, grouped)
  end

  defp process_tree_item(
         [%{type: "category", total_only: true} = c | rest],
         {_, _, totals},
         groups
       ) do
    {total_lines, _} = collect_accounts([c], [], totals)

    grouped =
      groups ++
        [
          %{
            "name" => c.name,
            "type" => "list",
            "groups" => [],
            "accounts" => total_lines,
            "total_only" => true
          }
        ]

    process_tree_item(rest, {0, 99_999_999, totals}, grouped)
  end

  defp process_tree_item(rest, _, groups) do
    {groups, rest}
  end

  defp collect_totals(%{total_only: true, num: num} = c, list, lines) do
    max = Accounting.category_max(c)
    Map.put(lines, max, Enum.reduce(list, [], &collect_total_accounts(&1, num, max, &2)))
  end

  defp collect_totals(_, _, lines), do: lines

  defp collect_total_accounts(line, min, max, collected) do
    if line.type == "account" and min <= line.num and max >= line.num do
      collected ++ [line.id]
    else
      collected
    end
  end

  defp sort_num(%{total_only: true} = c), do: Accounting.category_max(c)
  defp sort_num(%{num: n}), do: n

  defp collect_accounts([%{type: "category", total_only: true} = l | rest], accounts, totals) do
    collect_accounts(
      rest,
      accounts ++ [%{"name" => l.name, "total" => totals[Accounting.category_max(l)]}],
      totals
    )
  end

  defp collect_accounts([%{type: "account", id: id, source_id: s_id} | rest], accounts, totals)
       when not is_nil(s_id) do
    account_ids =
      from(
        c in Category,
        where: c.id == ^s_id,
        left_join: a in Account,
        on: a.num <= c.max and a.num >= c.num,
        select: a.id
      )
      |> Repo.all()

    collect_accounts(rest, accounts ++ [%{"id" => id, "ids" => account_ids}], totals)
  end

  defp collect_accounts([%{type: "account", id: id} | rest], accounts, totals) do
    collect_accounts(rest, accounts ++ [%{"id" => id}], totals)
  end

  defp collect_accounts(rest, accounts, _) do
    {accounts, rest}
  end
end
