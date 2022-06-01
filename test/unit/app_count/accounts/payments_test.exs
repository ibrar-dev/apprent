defmodule AppCount.Accounts.PaymentsTest do
  use AppCount.DataCase
  import AppCount.LeaseHelper
  alias AppCount.Accounts
  alias AppCount.Properties
  alias AppCount.Accounts.PaymentSource
  alias AppCount.Core.ClientSchema
  alias AppCount.Support.HTTPClient
  @moduletag :accounts_payments

  @payment_response """
  <?xml version="1.0" encoding="utf-8"?><createTransactionResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transactionResponse><responseCode>1</responseCode><authCode>2SXPZY</authCode><avsResultCode>Y</avsResultCode><cvvResultCode>P</cvvResultCode><cavvResultCode>2</cavvResultCode><transId>60118835356</transId><refTransID /><transHash /><testRequest>0</testRequest><accountNumber>XXXX1111</accountNumber><accountType>Visa</accountType><messages><message><code>1</code><description>This transaction has been approved.</description></message></messages><transHashSha2 /></transactionResponse></createTransactionResponse>
  """

  setup do
    payment_source = insert(:payment_source)
    unit = insert(:unit, property: payment_source.account.property)

    insert_lease(%{
      unit: unit,
      property: payment_source.account.property,
      tenants: [payment_source.account.tenant],
      charges: [
        Rent: 800
      ],
      end_date: Timex.shift(AppCount.current_date(), months: 6)
    })

    Properties.create_processor(
      ClientSchema.new(
        "dasmen",
        %{
          "name" => "Authorize",
          "type" => "cc",
          "property_id" => payment_source.account.property.id,
          "keys" => ["123456", "7891011", "12131415"]
        }
      )
    )

    {:ok, payment_source: payment_source}
  end

  test "create_payment", %{payment_source: ps} do
    HTTPClient.initialize([@payment_response])

    {:ok, payment} =
      %{
        "account_id" => ps.account_id,
        "amount" => 150,
        "payment_source_id" => ps.id,
        "agreement_text" => "test agreement test",
        "agreement_accepted_at" => ~N[2000-01-01 23:00:07],
        "payer_ip_address" => "127.0.0.1",
        "status" => "approved"
      }
      |> Accounts.create_payment()

    assert payment.amount == Decimal.new(150)
    assert payment.batch_id
    assert payment.last_4 == "1111"
    assert payment.payment_type == "cc"
    assert payment.payer_name == "William Smith"
    HTTPClient.stop()
  end

  test "lock_and_return_source/1", %{payment_source: ps} do
    result = Accounts.Utils.Payments.lock_and_return_source(ps.id)

    updated_ps = Repo.get(PaymentSource, ps.id)

    assert is_nil(result.lock)
    assert not is_nil(updated_ps.lock)
  end
end
