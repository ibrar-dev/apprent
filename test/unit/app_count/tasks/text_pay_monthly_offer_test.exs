defmodule AppCount.Tasks.TextPayMonthlyOfferTest do
  use AppCount.DataCase
  alias AppCount.Support.AccountBuilder
  alias AppCount.Tasks.Workers.TextPayMonthlyOffer, as: Subject
  alias AppCount.Messaging.Utils.TextMessageTemplates
  alias AppCount.Messaging.PhoneNumberRepo
  alias AppCount.Tenants.TenantRepo
  alias AppCount.Accounts
  alias AppCount.Core.SmsTopic
  alias AppCount.Core.DomainEvent

  @phone "1234567890"

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
      |> PropBuilder.add_ledger_charge()
      |> PropBuilder.add_tenancy()
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

  def update_account_arg(tenant, account) do
    %{
      account_id: account.id,
      id: tenant.id
    }
  end

  describe "perform/1 works" do
    setup(~M[tenant, payment_source, property]) do
      offer_to_pay_params = %{
        first_name: tenant.first_name,
        property_name: property.name,
        last_4: payment_source.last_4,
        balance: "950.00"
      }

      ~M[offer_to_pay_params]
    end

    test "receives successful message(s)", ~M[offer_to_pay_params, property] do
      SmsTopic.subscribe()

      Subject.perform(property.id)

      expected_reply = TextMessageTemplates.offer_to_pay(offer_to_pay_params, nil)

      assert_receive %DomainEvent{
        topic: "sms",
        name: "sms_requested",
        content: %{phone_to: @phone, message: ^expected_reply}
      }
    end

    test "receives successful message with property from number with payments context",
         ~M[offer_to_pay_params, property] do
      property_number = "+15558675309"

      PhoneNumberRepo.create(%{
        number: property_number,
        property_id: property.id,
        context: "payments"
      })

      SmsTopic.subscribe()

      Subject.perform(property.id)

      expected_reply = TextMessageTemplates.offer_to_pay(offer_to_pay_params, nil)

      assert_receive %DomainEvent{
        topic: "sms",
        name: "sms_requested",
        content: %{phone_to: @phone, phone_from: ^property_number, message: ^expected_reply}
      }
    end

    test "receives successful message with property from number with all context",
         ~M[offer_to_pay_params, property] do
      property_number = "+15558675309"

      PhoneNumberRepo.create(%{number: property_number, property_id: property.id, context: "all"})

      SmsTopic.subscribe()

      Subject.perform(property.id)

      expected_reply = TextMessageTemplates.offer_to_pay(offer_to_pay_params, nil)

      assert_receive %DomainEvent{
        topic: "sms",
        name: "sms_requested",
        content: %{phone_to: @phone, phone_from: ^property_number, message: ^expected_reply}
      }
    end
  end

  describe "perform/1 does not work when" do
    setup(~M[tenant, payment_source, property]) do
      offer_to_pay_params = %{
        first_name: tenant.first_name,
        property_name: property.name,
        last_4: payment_source.last_4,
        balance: "950.00"
      }

      ~M[offer_to_pay_params]
    end

    @tag :slow
    test "filters out tenants with sms_allowed:false",
         ~M[property, tenant, offer_to_pay_params] do
      SmsTopic.subscribe()

      TenantRepo.update(tenant, %{payment_status: "gibberish"})

      Subject.perform(property.id)

      expected_reply = TextMessageTemplates.offer_to_pay(offer_to_pay_params, nil)

      refute_receive %DomainEvent{
        topic: "sms",
        name: "sms_requested",
        content: %{phone_to: @phone, message: ^expected_reply}
      }
    end

    @tag :slow
    test "filters out tenants with no active payment source",
         ~M[property, payment_source, offer_to_pay_params] do
      SmsTopic.subscribe()

      Accounts.delete_payment_source(payment_source.id)

      Subject.perform(property.id)

      expected_reply = TextMessageTemplates.offer_to_pay(offer_to_pay_params, nil)

      refute_receive %DomainEvent{
        topic: "sms",
        name: "sms_requested",
        content: %{phone_to: @phone, message: ^expected_reply}
      }
    end

    test "filters out tenants who cannot pay online", ~M[property, tenant, offer_to_pay_params] do
      SmsTopic.subscribe()

      TenantRepo.update(tenant, %{payment_status: "cash"})

      Subject.perform(property.id)

      expected_reply = TextMessageTemplates.offer_to_pay(offer_to_pay_params, nil)

      refute_receive %DomainEvent{
        topic: "sms",
        name: "sms_requested",
        content: %{phone_to: @phone, message: ^expected_reply}
      }
    end
  end
end
