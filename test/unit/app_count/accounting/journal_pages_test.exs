defmodule AppCount.Accounting.JournalPagesTest do
  use AppCount.DataCase
  alias AppCount.Accounting
  alias AppCount.Repo
  alias AppCount.Accounting.JournalPage
  @moduletag :journal_pages

  setup do
    entry = insert(:journal_entry)
    {:ok, journal_page: entry.page}
  end

  test "list_journal_pages", %{journal_page: journal_page} do
    result = Accounting.list_journal_pages()
    assert length(result) == 1
    assert hd(result).id == journal_page.id
  end

  test "create_journal_page" do
    account = insert(:account)
    property = insert(:property)

    {:ok, result} =
      Accounting.create_journal_page(%{
        "name" => "Good Page Name",
        "date" => "2018-05-26",
        "cash" => true,
        "entries" => [
          %{
            "is_credit" => true,
            "account_id" => account.id,
            "amount" => 230,
            "property_id" => property.id
          },
          %{"account_id" => account.id, "amount" => 180, "property_id" => property.id},
          %{"account_id" => account.id, "amount" => 50, "property_id" => property.id}
        ]
      })

    assert result.journal_page.name == "Good Page Name"
    assert result.journal_page.cash

    page =
      Repo.get_by(JournalPage, name: "Good Page Name")
      |> Repo.preload(:entries)

    assert length(page.entries) == 3
  end

  test "journal page error handling", %{journal_page: journal_page} do
    account = insert(:account)
    property = insert(:property)

    {:error, :entries, "Entry amounts must equal zero for each property", _} =
      Accounting.create_journal_page(%{
        "name" => "Bad Page Name",
        "date" => "2018-05-26",
        "cash" => true,
        "entries" => [
          %{
            "is_credit" => true,
            "account_id" => account.id,
            "amount" => 230,
            "property_id" => property.id
          },
          %{"account_id" => account.id, "amount" => 180, "property_id" => property.id},
          %{"account_id" => account.id, "amount" => 40, "property_id" => property.id}
        ]
      })

    refute Repo.get_by(JournalPage, name: "Bad Page Name")

    {:error, :entries, "Entry amounts must equal zero for each property", _} =
      Accounting.update_journal_page(
        journal_page.id,
        %{
          "name" => "Ridiculous New Name",
          "entries" => [
            %{
              "is_credit" => true,
              "account_id" => account.id,
              "amount" => 230,
              "property_id" => property.id
            },
            %{"account_id" => account.id, "amount" => 180, "property_id" => property.id},
            %{"account_id" => account.id, "amount" => 70, "property_id" => property.id}
          ]
        }
      )

    refute Repo.get_by(JournalPage, name: "Ridiculous New Name")
  end

  test "update_journal_page", %{journal_page: journal_page} do
    account = insert(:account)
    property = insert(:property)

    {:ok, result} =
      Accounting.update_journal_page(
        journal_page.id,
        %{
          "name" => "Ridiculous New Name",
          "entries" => [
            %{
              "is_credit" => true,
              "account_id" => account.id,
              "amount" => 230,
              "property_id" => property.id
            },
            %{"account_id" => account.id, "amount" => 180, "property_id" => property.id},
            %{"account_id" => account.id, "amount" => 50, "property_id" => property.id}
          ]
        }
      )

    assert result.journal_page.name == "Ridiculous New Name"

    page =
      Repo.get_by(JournalPage, name: "Ridiculous New Name")
      |> Repo.preload(:entries)

    assert length(page.entries) == 3
  end

  test "delete_journal_page", %{journal_page: journal_page} do
    Accounting.delete_journal_page(journal_page.id)
    refute Repo.get(JournalPage, journal_page.id)
  end
end
