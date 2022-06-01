defmodule AppCountWeb.Requests.Users.PaymentsTest do
  use AppCountWeb.ConnCase
  alias AppCount.Support.HTTPClient
  alias AppCount.Core.ClientSchema
  use Bamboo.Test, shared: true

  @payment_response """
  <?xml version="1.0" encoding="utf-8"?><createTransactionResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transactionResponse><responseCode>1</responseCode><authCode>2SXPZY</authCode><avsResultCode>Y</avsResultCode><cvvResultCode>P</cvvResultCode><cavvResultCode>2</cavvResultCode><transId>60118835356</transId><refTransID /><transHash /><testRequest>0</testRequest><accountNumber>XXXX1111</accountNumber><accountType>Visa</accountType><messages><message><code>1</code><description>This transaction has been approved.</description></message></messages><transHashSha2 /></transactionResponse></createTransactionResponse>
  """

  @export_payment_success File.read!(
                            Path.expand(
                              "../../resources/Yardi/export_payment_success.xml",
                              __DIR__
                            )
                          )

  setup do
    property = insert(:property, setting: nil, external_id: "3030")
    insert(:setting, property_id: property.id, sync_payments: true, integration: "Yardi")
    tenant = insert(:tenant, external_id: "p12345667")

    insert(:tenancy,
      tenant: tenant,
      unit: insert(:unit, property: property),
      external_id: "t1234556"
    )

    account =
      insert(:user_account, tenant: tenant, property: property)
      |> AppCount.UserHelper.new_account()

    insert(:processor, name: "Authorize", type: "cc", property: property)

    insert(:processor,
      name: "Yardi",
      type: "management",
      keys: ["A", "B", "C", "D", "E", "F", "G", "H", "I"],
      property: property
    )

    {:ok, account: account}
  end

  test "residents. GET /payments", %{conn: conn, account: account} do
    response =
      conn
      |> user_request(account)
      |> get("http://residents.example.com/payments")
      |> html_response(200)

    assert response =~ "#{account.tenant.first_name} #{account.tenant.last_name}"
    assert response =~ "AppRent"
  end

  test "residents. POST /payments", %{conn: conn, account: account} do
    AppCount.Core.PaymentTopic.subscribe()
    ref = AppCount.Support.SynchronousQueue.monitor_queue()
    payment_source_id = insert(:payment_source, account: account).id

    params = %{
      "payment" => %{
        "payment_source_id" => payment_source_id,
        "amount_in_cents" => 10000,
        "agreement_text" => "I hereby agree to whatever"
      }
    }

    HTTPClient.initialize([@payment_response, @export_payment_success])

    response =
      conn
      |> user_request(account)
      |> post("http://residents.example.com/payments", params)
      |> json_response(201)

    assert response["amount_in_cents"] == 10000
    assert response["payment_source_id"] == payment_source_id
    assert response["zip_code_confirmed_at"]
    assert response["payment_confirmed_at"]
    assert response["cvv_confirmed_at"]
    assert response["failed_at"] == nil
    assert response["property_id"] == account.property.id

    assert_receive %AppCount.Core.DomainEvent{
      name: "payment_confirmed",
      content: %ClientSchema{
        name: "dasmen",
        attrs: %{
          rent_saga_id: _
        }
      }
    }

    # wait for queued task to run
    assert_receive {:DOWN, ^ref, :process, _, :killed}, 500

    payment =
      Repo.get_by(
        AppCount.Ledgers.Payment,
        [payment_source_id: payment_source_id],
        prefix: "dasmen"
      )

    assert payment
    # dumb Bamboo doesn't let us set our own timeout :(
    Process.sleep(200)

    assert_email_delivered_with(
      subject: "[AppRent] Received your payment",
      html_body: ~r/This email is to confirm that we have received your online payment to/,
      to: [
        nil: account.tenant.email
      ]
    )

    task =
      Repo.get_by(
        AppCount.Jobs.Task,
        [description: "Export payment #{payment.id}"],
        prefix: "dasmen"
      )

    assert task
    assert task.error == nil
    HTTPClient.stop()
  end
end
