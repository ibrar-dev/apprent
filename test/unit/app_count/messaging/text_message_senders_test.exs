defmodule AppCount.Messaging.TextMessageSendersTest do
  use AppCount.DataCase
  alias AppCount.Support.AccountBuilder
  alias AppCount.Messaging.Utils.TextMessageSenders
  alias AppCount.Messaging.Utils.TextMessageTemplates
  alias AppCount.Messaging.PhoneNumberRepo
  alias AppCount.Tenants.TenantRepo
  alias AppCount.Accounts
  alias AppCount.Core.SmsTopic
  alias AppCount.Core.DomainEvent

  @phone "1234567890"
  # For successful processing tenant must have:
  ##  phone, account, account.allow_sms = true, active payment_source
  setup do
    [builder, property] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_processor(type: "cc")
      |> PropBuilder.get([:property])

    [prop_builder, tenant] =
      builder
      |> PropBuilder.add_unit()
      |> PropBuilder.add_tenant(phone: @phone)
      |> PropBuilder.add_customer_ledger()
      |> PropBuilder.add_tenancy()
      |> PropBuilder.add_ledger_charge()
      |> PropBuilder.get([:tenant])

    [account_builder, account, payment_source] =
      AccountBuilder.new(:create)
      |> AccountBuilder.put_requirement(:tenant, tenant)
      |> AccountBuilder.put_requirement(:property, property)
      |> AccountBuilder.add_account()
      |> AccountBuilder.add_payment_source()
      |> AccountBuilder.get([:account, :payment_source])

    ~M[tenant, account, account_builder, prop_builder, property, payment_source]
  end

  describe " offer_to_pay/1 " do
    setup(~M[tenant, payment_source, property, account]) do
      offer_to_pay_params = %{
        first_name: tenant.first_name,
        property_name: property.name,
        last_4: payment_source.last_4,
        balance: "950.00"
      }

      update_account_arg_1 = %{
        account_id: account.id,
        id: tenant.id
      }

      ~M[offer_to_pay_params, update_account_arg_1]
    end

    test "successful offer", ~M[tenant, account, offer_to_pay_params] do
      SmsTopic.subscribe()

      expected_reply =
        TextMessageTemplates.offer_to_pay(offer_to_pay_params, account.preferred_language)

      TextMessageSenders.offer_to_pay(tenant.id)

      assert_receive %DomainEvent{
        topic: "sms",
        name: "sms_requested",
        content: %{phone_to: @phone, message: ^expected_reply}
      }
    end

    test "successful offer correct from number",
         ~M[tenant, account, property, offer_to_pay_params] do
      property_number = "+15558675309"

      PhoneNumberRepo.create(%{
        number: property_number,
        property_id: property.id,
        context: "payments"
      })

      SmsTopic.subscribe()

      expected_reply =
        TextMessageTemplates.offer_to_pay(offer_to_pay_params, account.preferred_language)

      TextMessageSenders.offer_to_pay(tenant.id)

      assert_receive %DomainEvent{
        topic: "sms",
        name: "sms_requested",
        content: %{phone_to: @phone, phone_from: ^property_number, message: ^expected_reply}
      }
    end

    test "successful offer incorrect from number",
         ~M[tenant, account, property, offer_to_pay_params] do
      property_number = "+15558675309"

      PhoneNumberRepo.create(%{
        number: property_number,
        property_id: property.id,
        context: "gibberish"
      })

      SmsTopic.subscribe()

      expected_reply =
        TextMessageTemplates.offer_to_pay(offer_to_pay_params, account.preferred_language)

      TextMessageSenders.offer_to_pay(tenant.id)

      assert_receive %DomainEvent{
        topic: "sms",
        name: "sms_requested",
        content: %{phone_to: @phone, phone_from: nil, message: ^expected_reply}
      }
    end

    test "fails because unable to text", ~M[tenant, update_account_arg_1] do
      Accounts.update_account(update_account_arg_1, %{allow_sms: false})

      res = TextMessageSenders.offer_to_pay(tenant.id)

      assert res == {:error, "SMS Not Allowed"}
    end

    test "fails because no payment source", ~M[tenant, payment_source] do
      Accounts.delete_payment_source(payment_source.id)

      res = TextMessageSenders.offer_to_pay(tenant.id)

      assert res == {:error, "Missing Payment Source"}
    end

    test "fails because tenant_id is wrong" do
      res = TextMessageSenders.offer_to_pay(234_567_890)

      assert res == {:error, "Invalid Tenant ID"}
    end

    test "fails because online payments not allowed for tenant", ~M[tenant] do
      TenantRepo.update(tenant, %{payment_status: "cash"})

      res = TextMessageSenders.offer_to_pay(tenant.id)

      assert res == {:error, "Payments Not Allowed"}
    end
  end
end
