defmodule AppCount.Accounting.ReportTemplatesTest do
  use AppCount.DataCase
  alias AppCount.Accounting
  alias AppCount.Repo
  alias AppCount.Accounting.ReportTemplate
  @moduletag :report_templates

  test "list_report_templates, create_report_template, update_report_template and delete_report_template" do
    {:ok, result} =
      Accounting.create_report_template(%{
        "name" => "Special Report",
        "groups" => [
          %{
            "name" => "ASSETS",
            "type" => "list",
            "groups" => [
              %{
                "name" => "BANK ACCOUNTS/CASH",
                "type" => "list",
                "groups" => [],
                "accounts" => [%{"id" => 64}]
              }
            ]
          }
        ]
      })

    assert result.name == "Special Report"
    assert length(result.groups) == 1
    list = Accounting.list_report_templates()
    assert length(list) == 1

    {:ok, result} =
      Accounting.update_report_template(result.id, %{"name" => "Not So Special Anymore"})

    assert result.name == "Not So Special Anymore"
    Accounting.delete_report_template(result.id)
    refute Repo.get(ReportTemplate, result.id)
  end

  test "balance_template" do
    insert(:account_category, name: "Super", num: 10_000_000, max: 19_999_999, is_balance: true)
    insert(:account_category, name: "Sub", num: 11_000_000, max: 11_999_999, is_balance: true)
    insert(:account_category, name: "Sub-2", num: 12_000_000, max: 12_999_999, is_balance: true)
    insert(:account_category, name: "Super-2", num: 20_000_000, max: 29_999_999, is_balance: true)
    insert(:account_category, name: "Non", num: 30_000_000, max: 39_999_999, is_balance: false)

    insert(:account_category,
      name: "Totals",
      num: 10_000_001,
      max: 21_500_000,
      is_balance: true,
      total_only: true
    )

    a1 = insert(:account, name: "First", num: 11_100_000, is_balance: true)
    a2 = insert(:account, name: "Second", num: 11_200_000, is_balance: true)
    a3 = insert(:account, name: "Third", num: 11_300_000, is_balance: true)
    a4 = insert(:account, name: "Fourth", num: 12_100_000, is_balance: true)
    a5 = insert(:account, name: "Fifth", num: 21_000_000, is_balance: true)
    a6 = insert(:account, name: "Sixth", num: 22_000_000, is_balance: true)
    insert(:account, name: "Non", num: 31_000_000, is_balance: false)

    expected = %{
      name: "Balance Sheet",
      is_balance: true,
      groups: [
        %{
          "name" => "Super",
          "type" => "list",
          "total_only" => false,
          "accounts" => [],
          "groups" => [
            %{
              "name" => "Sub",
              "type" => "list",
              "total_only" => false,
              "accounts" => [%{"id" => a1.id}, %{"id" => a2.id}, %{"id" => a3.id}],
              "groups" => []
            },
            %{
              "name" => "Sub-2",
              "type" => "list",
              "total_only" => false,
              "accounts" => [%{"id" => a4.id}],
              "groups" => []
            }
          ]
        },
        %{
          "name" => "Super-2",
          "type" => "list",
          "total_only" => false,
          "accounts" => [
            %{"id" => a5.id},
            %{"name" => "Totals", "total" => [a1.id, a2.id, a3.id, a4.id, a5.id]},
            %{"id" => a6.id}
          ],
          "groups" => []
        }
      ]
    }

    assert Accounting.balance_template() == expected
  end

  test "balance_template with total_only" do
    insert(:account_category, name: "Super", num: 10_000_000, max: 19_999_999, is_balance: true)
    insert(:account_category, name: "Sub", num: 11_000_000, max: 11_999_999, is_balance: true)
    insert(:account_category, name: "Sub-2", num: 12_000_000, max: 12_999_999, is_balance: true)
    insert(:account_category, name: "Super-2", num: 20_000_000, max: 29_999_999, is_balance: true)
    insert(:account_category, name: "Non", num: 30_000_000, max: 39_999_999, is_balance: false)

    insert(:account_category,
      name: "Totals",
      num: 10_000_001,
      max: 99_999_999,
      is_balance: true,
      total_only: true
    )

    a1 = insert(:account, name: "First", num: 11_100_000, is_balance: true)
    a2 = insert(:account, name: "Second", num: 11_200_000, is_balance: true)
    a3 = insert(:account, name: "Third", num: 11_300_000, is_balance: true)
    a4 = insert(:account, name: "Fourth", num: 12_100_000, is_balance: true)
    a5 = insert(:account, name: "Fifth", num: 21_000_000, is_balance: true)
    a6 = insert(:account, name: "Sixth", num: 22_000_000, is_balance: true)
    insert(:account, name: "Non", num: 31_000_000, is_balance: false)

    expected = %{
      name: "Balance Sheet",
      is_balance: true,
      groups: [
        %{
          "name" => "Super",
          "type" => "list",
          "total_only" => false,
          "accounts" => [],
          "groups" => [
            %{
              "name" => "Sub",
              "type" => "list",
              "total_only" => false,
              "accounts" => [%{"id" => a1.id}, %{"id" => a2.id}, %{"id" => a3.id}],
              "groups" => []
            },
            %{
              "name" => "Sub-2",
              "type" => "list",
              "total_only" => false,
              "accounts" => [%{"id" => a4.id}],
              "groups" => []
            }
          ]
        },
        %{
          "name" => "Super-2",
          "type" => "list",
          "total_only" => false,
          "accounts" => [
            %{"id" => a5.id},
            %{"id" => a6.id}
          ],
          "groups" => []
        },
        %{
          "name" => "Totals",
          "type" => "list",
          "total_only" => true,
          "accounts" => [
            %{"name" => "Totals", "total" => [a1.id, a2.id, a3.id, a4.id, a5.id, a6.id]}
          ],
          "groups" => []
        }
      ]
    }

    assert Accounting.balance_template() == expected
  end
end
