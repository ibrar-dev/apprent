defmodule AppCount.Ledgers.PaymentsTest do
  use AppCount.DataCase
  alias AppCount.Accounting
  alias AppCount.Ledgers
  alias AppCount.Ledgers.Utils.Payments
  alias AppCount.Properties
  alias AppCount.Repo
  alias AppCount.Core.ClientSchema

  @payment_response """
  <?xml version="1.0" encoding="utf-8"?><createTransactionResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="AnetApi/xml/v1/schema/AnetApiSchema.xsd"><messages><resultCode>Ok</resultCode><message><code>I00001</code><text>Successful.</text></message></messages><transactionResponse><responseCode>1</responseCode><authCode>2SXPZY</authCode><avsResultCode>Y</avsResultCode><cvvResultCode>P</cvvResultCode><cavvResultCode>2</cavvResultCode><transId>60118835356</transId><refTransID /><transHash /><testRequest>0</testRequest><accountNumber>XXXX1111</accountNumber><accountType>Visa</accountType><messages><message><code>1</code><description>This transaction has been approved.</description></message></messages><transHashSha2 /></transactionResponse></createTransactionResponse>
  """
  @moduletag :payments

  setup do
    prop = insert(:property)
    lease = insert(:lease, unit: insert(:unit, property: prop))
    batch = insert(:batch)

    {
      :ok,
      payment: insert(:payment, property: prop, tenant: hd(lease.tenants), batch: batch),
      property: prop,
      admin: %{
        roles: MapSet.new(["Super Admin"]),
        name: "SuperAdmin!",
        id: 123
      }
    }
  end

  test "payment lease_id hook works" do
    today = DateTime.utc_now()
    tenant = insert(:tenant)

    lease1 =
      insert(:lease, start_date: today, end_date: Timex.shift(today, years: 1), tenants: [tenant])

    lease2 =
      insert(
        :lease,
        start_date: Timex.shift(today, years: 1, days: 1),
        end_date: Timex.shift(today, years: 2, days: 1),
        tenants: [tenant]
      )

    payment = insert(:payment, tenant: tenant, inserted_at: Timex.shift(today, months: -1))
    Accounting.Receipts.PaymentLease.match_payment_to_lease(payment)
    assert Repo.get(Ledgers.Payment, payment.id).lease_id == lease1.id
    payment = insert(:payment, tenant: tenant, inserted_at: Timex.shift(today, months: 1))
    Accounting.Receipts.PaymentLease.match_payment_to_lease(payment)
    assert Repo.get(Ledgers.Payment, payment.id).lease_id == lease1.id

    payment =
      insert(:payment, tenant: tenant, inserted_at: Timex.shift(today, years: 1, months: 1))

    Accounting.Receipts.PaymentLease.match_payment_to_lease(payment)
    assert Repo.get(Ledgers.Payment, payment.id).lease_id == lease2.id

    payment =
      insert(:payment, tenant: tenant, inserted_at: Timex.shift(today, years: 2, months: 1))

    Accounting.Receipts.PaymentLease.match_payment_to_lease(payment)
    assert Repo.get(Ledgers.Payment, payment.id).lease_id == lease2.id
    payment = insert(:payment, inserted_at: Timex.shift(today, years: 2, months: 1))
    Accounting.Receipts.PaymentLease.match_payment_to_lease(payment)
    assert Repo.get(Ledgers.Payment, payment.id).lease_id == nil
  end

  test "list_payments", %{payment: payment, admin: admin, property: prop} do
    start =
      Timex.shift(payment.batch.inserted_at, days: -1)
      |> Timex.format!("{YYYY}-{M}-{D}")

    end_t =
      Timex.shift(payment.batch.inserted_at, days: 1)
      |> Timex.format!("{YYYY}-{M}-{D}")

    params = %{"start" => start, "end" => end_t, "property_id" => prop.id}
    result = Payments.list_payments(ClientSchema.new("dasmen", admin), params)
    assert length(result) == 1
    payment_res = hd(result)
    assert payment_res.tenant_name == "#{payment.tenant.first_name} #{payment.tenant.last_name}"
    assert payment_res.property_name == payment.property.name
  end

  test "create_admin_payment" do
    {:ok, payment} =
      Payments.create_admin_payment(
        ClientSchema.new("dasmen", %{
          "amount" => 200,
          "description" => "Administration Fee",
          "transaction_id" => "123456",
          "source" => "admin",
          "property_id" => insert(:property).id
        })
      )

    assert payment.id
    assert payment.description == "Administration Fee"
    assert Decimal.equal?(payment.amount, Decimal.new(200))
  end

  test "get_payment_image" do
    path = Path.expand("../../resources/sample.png", __DIR__)
    image = insert(:upload, filename: path)
    payment = insert(:payment, image: image)

    assert Payments.get_payment_image(ClientSchema.new("dasmen", payment.id)) =~
             ~r"/test/.*/sample.png"
  end

  test "delete_payment", %{payment: payment} do
    client = AppCount.Public.get_client_by_schema("dasmen")

    super_admin = AppCount.UserHelper.new_admin(%{roles: ["Super Admin"]})

    super_admin = Repo.get(AppCount.Admins.Admin, super_admin.id, prefix: client.client_schema)

    Payments.delete_payment(super_admin, ClientSchema.new(client.client_schema, payment.id))
    assert Repo.all(Ledgers.Payment, prefix: client.client_schema) == []
  end

  test "update_payment", %{admin: admin, payment: payment} do
    Payments.update_payment(admin, payment.id, ClientSchema.new("dasmen", %{"amount" => 1234}))
    updated = Repo.get(Ledgers.Payment, payment.id)
    assert Decimal.equal?(updated.amount, Decimal.new(50))
    assert updated.status == "voided"

    assert Repo.get_by(
             Ledgers.Payment,
             amount: 1234,
             tenant_id: payment.tenant_id,
             status: payment.status
           )

    Payments.update_payment(
      admin,
      payment.id,
      ClientSchema.new("dasmen", %{"description" => "QWERTY"})
    )

    updated = Repo.get(Ledgers.Payment, payment.id)
    assert updated.description == "QWERTY"
  end

  test "process_payment" do
    ps = insert(:payment_source)

    Properties.create_processor(
      ClientSchema.new(
        "dasmen",
        %{
          "name" => "Authorize",
          "type" => "cc",
          "property_id" => ps.account.property.id,
          "keys" => ["123456", "7891011", "12131415"]
        }
      )
    )

    AppCount.Support.HTTPClient.initialize([@payment_response])
    {:ok, payment} = Payments.process_payment(ps.account.property.id, 450.0, ps)
    assert payment.transaction_id == "60118835356"
    assert payment.auth_code == "2SXPZY"
    assert payment.account_number == "XXXX1111"
    AppCount.Support.HTTPClient.stop()
  end
end
