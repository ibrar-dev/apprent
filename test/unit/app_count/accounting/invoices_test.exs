defmodule AppCount.Accounting.InvoicesTest do
  use AppCount.DataCase
  alias AppCount.Accounting
  alias AppCount.Repo
  alias AppCount.Accounting.Invoice
  @moduletag :invoices

  setup do
    {
      :ok,
      invoice: insert(:invoice),
      admin: %{
        roles: MapSet.new(["Super Admin"]),
        id: 234
      }
    }
  end

  test "list_invoices", %{invoice: invoice, admin: admin} do
    insert(:invoicing, invoice: invoice)
    result = Accounting.list_invoices(admin)
    assert length(result) == 1

    keys =
      hd(result)
      |> Map.keys()

    assert length(keys) == 13
  end

  test "create_invoice" do
    invoicing_account = insert(:account)

    {:ok, %{invoice: result}} =
      Accounting.create_invoice(%{
        "post_month" => "2018-04-01",
        "payee_id" => insert(:payee).id,
        "number" => "123456",
        "due_date" => "2018-05-01",
        "date" => "2018-05-01",
        "amount" => 500,
        "payable_account_id" => insert(:account).id,
        "invoicings" => [
          %{
            "amount" => 100,
            "account_id" => invoicing_account.id,
            "property_id" => insert(:property).id
          },
          %{
            "amount" => 240,
            "account_id" => invoicing_account.id,
            "property_id" => insert(:property).id
          },
          %{
            "amount" => 160,
            "account_id" => invoicing_account.id,
            "property_id" => insert(:property).id
          }
        ]
      })

    assert result.post_month == %Date{year: 2018, month: 4, day: 1}
    assert result.due_date == %Date{year: 2018, month: 5, day: 1}
    assert length(Repo.preload(result, :invoicings).invoicings) == 3
  end

  @tag :slow
  test "list_invoicings", %{invoice: invoice, admin: admin} do
    i1 = insert(:invoicing, invoice: invoice)
    i2 = insert(:invoicing, invoice: invoice)
    i3 = insert(:invoicing, invoice: invoice)
    insert(:accounting_entity, property: i1.property)
    insert(:accounting_entity, property: i2.property)
    insert(:accounting_entity, property: i3.property)
    result = Accounting.list_invoicings(admin)
    assert length(result) == 3

    keys =
      hd(result)
      |> Map.keys()

    assert length(keys) == 16
  end

  test "update_invoice", %{invoice: invoice} do
    {:ok, %Invoice{} = result} = Accounting.update_invoice(invoice.id, %{number: "987654321"})
    assert result.number == "987654321"
  end

  test "delete_invoice", %{invoice: invoice} do
    {:ok, %Invoice{}} = Accounting.delete_invoice(invoice.id)
    refute Repo.get(Invoice, invoice.id)
  end

  test "get_invoice", %{invoice: invoice} do
    %Invoice{} = result = Accounting.get_invoice(invoice.id)
    assert result.number == invoice.number
    assert result.id == invoice.id
  end

  test "create_invoice_payment and delete_invoice_payment", %{invoice: invoice} do
    i1 = insert(:invoicing, invoice: invoice)

    params = %{
      "invoicing_id" => i1.id,
      "check" => %{
        "number" => "129567824",
        "date" => "2018-06-15",
        "payee_id" => insert(:payee).id,
        "bank_account_id" => insert(:bank_account).id,
        "amount" => 20
      },
      "amount" => 20,
      "account_id" => insert(:account, is_cash: true).id
    }

    {:ok, result} = Accounting.create_invoice_payment(params)
    assert result.invoicing_id == i1.id
    assert Repo.get(Accounting.Check, result.check_id)
    Accounting.delete_invoice_payment(result.id)
    refute Repo.get(Accounting.InvoicePayment, result.id)
  end

  @tag :slow
  test "create_batch_payments", %{invoice: invoice} do
    ba = insert(:bank_account)
    # render_fn could be a stub
    render_fn = &AppCountWeb.LetterPreviewer.render_check_template/1

    %{
      "checks" => [
        %{
          "amount" => 700,
          "amount_lang" => "one thousand nine hundred eighty and 21/100",
          "bank_account_id" => ba.id,
          "date" => "2020-03-19T14:17:41.601Z",
          "invoicings" => [
            %{
              "amount" => "100",
              "invoicing_id" => insert(:invoicing, amount: 100, invoice: invoice).id
            },
            %{
              "amount" => "250",
              "invoicing_id" => insert(:invoicing, amount: 250, invoice: invoice).id
            },
            %{
              "amount" => "350",
              "invoicing_id" => insert(:invoicing, amount: 350, invoice: invoice).id
            }
          ],
          "number" => "129567824",
          "payee_id" => insert(:payee).id
        },
        %{
          "amount" => 250,
          "amount_lang" => "two hundred fifty",
          "bank_account_id" => ba.id,
          "date" => "2020-03-19T14:17:43.209Z",
          "invoicings" => [
            %{"amount" => "250", "invoicing_id" => insert(:invoicing, amount: 250).id}
          ],
          "number" => "129567825",
          "payee_id" => insert(:payee).id
        }
      ]
    }
    |> Accounting.create_batch_payments(render_fn)

    assert Repo.get_by(Accounting.Check, number: 129_567_824, amount: 700)
    assert Repo.get_by(Accounting.Check, number: 129_567_825, amount: 250)
  end
end
