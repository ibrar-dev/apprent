defmodule AppCount.Accounting.Utils.JournalPages do
  alias AppCount.Accounting.Utils.Closings
  alias AppCount.Repo
  alias AppCount.Accounting.JournalPage
  alias AppCount.Accounting.JournalEntry
  alias Ecto.Multi
  import Ecto.Query
  import AppCount.EctoExtensions
  use AppCount.Decimal

  def list_journal_pages() do
    from(
      j in JournalPage,
      join: e in assoc(j, :entries),
      join: a in assoc(e, :account),
      join: p in assoc(e, :property),
      select: map(j, [:id, :date, :name, :cash, :accrual]),
      select_merge: %{
        total: sum(fragment("CASE WHEN ? = 't' THEN ? ELSE 0 END", e.is_credit, e.amount)),
        entries:
          jsonize(e, [
            :id,
            :amount,
            :account_id,
            :property_id,
            :is_credit,
            {:property, p.name},
            {:account, fragment("? || ' - ' || ?", a.num, a.name)}
          ])
      },
      order_by: [
        desc: j.date
      ],
      group_by: j.id
    )
    |> Repo.all()
  end

  def get_journal(id) do
    Repo.get(JournalPage, id)
  end

  def create_journal_page(%{"entries" => entries} = p) do
    params = Map.put(p, "post_month", page_post_date(p["date"], entries))

    Multi.new()
    |> Multi.insert(:journal_page, JournalPage.changeset(%JournalPage{}, params))
    |> process_entries(entries)
  end

  def update_journal_page(id, %{"entries" => entries} = params) do
    params =
      if params["date"] do
        Map.put(params, "post_month", page_post_date(params["date"], entries))
      else
        params
      end

    cs =
      Repo.get(JournalPage, id)
      |> JournalPage.changeset(params)

    Multi.new()
    |> Multi.update(:journal_page, cs)
    |> process_entries(entries)
  end

  def delete_journal_page(id) do
    Repo.get(JournalPage, id)
    |> Repo.delete()
  end

  defp page_post_date(date, entries) do
    Enum.reduce(
      entries,
      date,
      fn entry, d ->
        Closings.get_post_date(entry["property_id"], d, d, "journal_entries")
      end
    )
  end

  defp process_entries(multi, entries) do
    multi
    |> validate_entries(entries)
    |> save_entries(entries)
    |> clean_up_entries(entries)
    |> Repo.transaction()
  end

  defp save_entries(multi, entry_params) do
    entry_params
    |> Enum.with_index()
    |> Enum.reduce(
      multi,
      fn {e, index}, m ->
        Multi.run(m, :"entry_#{index + 1}", fn _repo, cs -> save_entry(e, cs.journal_page.id) end)
      end
    )
  end

  defp validate_entries(multi, params) do
    params
    |> Enum.reduce(
      %{},
      fn
        %{"is_credit" => true, "amount" => amount, "property_id" => property_id}, sums ->
          Map.update(sums, property_id, amount, &(&1 + amount))

        %{"amount" => amount, "property_id" => property_id}, sums ->
          Map.update(sums, property_id, amount * -1, &(&1 - amount))
      end
    )
    |> Map.values()
    |> Enum.all?(&(&1 == 0))
    |> if do
      multi
    else
      Multi.error(multi, :entries, "Entry amounts must equal zero for each property")
    end
  end

  defp save_entry(%{"id" => id} = params, _) do
    Repo.get(JournalEntry, id)
    |> JournalEntry.changeset(params)
    |> Repo.update()
  end

  defp save_entry(params, page_id) do
    %JournalEntry{}
    |> JournalEntry.changeset(Map.put(params, "page_id", page_id))
    |> Repo.insert()
  end

  defp clean_up_entries(multi, entries) do
    Multi.run(
      multi,
      :cleanup,
      fn _repo, cs ->
        ids =
          Enum.with_index(entries, 1)
          |> Enum.map(fn {_, index} -> cs[:"entry_#{index}"].id end)

        res =
          from(e in JournalEntry, where: e.page_id == ^cs.journal_page.id and e.id not in ^ids)
          |> Repo.delete_all()

        {:ok, res}
      end
    )
  end
end
