defmodule AppCount.Yardi.ExportPaymentCase do
  use AppCount.DataCase
  alias AppCount.Yardi.ExportPayment
  @moduletag :yardi_leasing_export_payment

  setup do
    property = insert(:property, external_id: "1234")
    insert(:processor, property: property, type: "management", name: "Yardi")
    tenant = insert(:tenant, external_id: "p12345")

    account = insert(:user_account, tenant: tenant)

    {:ok,
     payment: insert(:payment, property: property, tenant: tenant),
     tenancy: insert(:tenancy, external_id: "t4312", tenant: tenant),
     account: account,
     property: property}
  end

  describe "perform/2" do
    test "raises on bad inputs", %{payment: payment} do
      tenant_with_no_external_id = insert(:tenant, external_id: "p12386775")
      insert(:tenancy, tenant: tenant_with_no_external_id)

      assert_raise RuntimeError, "Payment Not found", fn ->
        ExportPayment.perform(0, "dasmen")
      end

      assert_raise RuntimeError, "Payment does not come from a tenant", fn ->
        ExportPayment.perform(insert(:payment).id, "dasmen")
      end

      assert_raise RuntimeError, "No external ID found for property Test Property", fn ->
        ExportPayment.perform(insert(:payment, tenant: tenant_with_no_external_id).id, "dasmen")
      end

      assert_raise RuntimeError, "No external ID found for tenant", fn ->
        ExportPayment.perform(
          insert(:payment, tenant: tenant_with_no_external_id, property: payment.property).id,
          "dasmen"
        )
      end
    end

    test "perform success", %{payment: payment} do
      ExportPayment.perform(payment.id, "dasmen", AppCount.Support.Yardi.FakeGateway)
      assert_receive {:log, "1 receipts were successfully imported into batch 1296679."}
    end

    test "perform failure", %{payment: payment, account: account, tenancy: tenancy} do
      admin = admin_with_access([payment.property.id])
      AppCount.Tenants.TenancyRepo.update(tenancy, %{external_id: "failure"})

      post_error =
        "Message Type=Error. Item Number=0. Payments from this tenant must be cash equivalent. (TranType=Receipt.)\nMessage Type=Error. Item Number=0. Error importing receipt for resident t0016708. Payments from this tenant must be cash equivalent.\nImport Failed.  Review Xml. 'Property Batch' = true\n"

      ExportPayment.perform(payment.id, "dasmen", AppCount.Support.Yardi.FakeGateway)

      assert Repo.get_by(AppCount.Accounts.Lock,
               account_id: account.id,
               reason: "Payments must be made in person in the office."
             )

      assert Repo.get_by(AppCount.Admins.Alert, admin_id: admin.id, sender: "AppRent")
      assert Repo.get(AppCount.Ledgers.Payment, payment.id).post_error == post_error
    end
  end

  describe "put_payment_date/1" do
    test "eastern time", ~M[property] do
      # 12a Feb 21 UTC --> 7p Feb 20 ET
      inserted_at_utc = ~N[2021-02-21 00:00:01]

      params = %{
        payment_inserted_at: inserted_at_utc,
        time_zone: property.time_zone
      }

      result = ExportPayment.put_payment_date(params)

      assert %{payment_date: ~D[2021-02-20]} = result
    end
  end
end
