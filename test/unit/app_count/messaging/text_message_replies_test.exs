defmodule AppCount.Messaging.TextMessageRepliesTest do
  use AppCount.DataCase
  alias AppCount.Messaging.Utils.TextMessageReplies
  alias AppCount.Messaging.Utils.TextMessageTemplates
  alias AppCount.Support.AccountBuilder
  alias AppCount.Tenants.TenantRepo
  alias AppCount.Core.SmsTopic
  alias AppCount.Core.DomainEvent
  alias AppCount.Accounts

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

    [account_builder, account] =
      AccountBuilder.new(:create)
      |> AccountBuilder.put_requirement(:tenant, tenant)
      |> AccountBuilder.put_requirement(:property, property)
      |> AccountBuilder.add_account()
      |> AccountBuilder.add_payment_source()
      |> AccountBuilder.get([:account])

    ~M[tenant, account, account_builder, prop_builder]
  end

  def add_tenant(builder) do
    builder
    |> PropBuilder.add_tenant(phone: @phone)
  end

  describe "helpers / get_language/1 " do
    test "get_language/1 binary" do
      res = TextMessageReplies.get_language(@phone)

      assert res == {:ok, "english"}
    end

    test "get_language/1 binary is spanish", ~M[tenant, account] do
      Accounts.update_account(
        %{account_id: account.id, id: tenant.id},
        %{preferred_language: "spanish"}
      )

      res = TextMessageReplies.get_language(tenant.phone)

      assert res == {:ok, "spanish"}
    end

    test "get_language/1 tenant is english", ~M[tenant] do
      tenant = TenantRepo.get_aggregate(tenant.id)

      res = TextMessageReplies.get_language(tenant)

      assert res == {:ok, "english"}
    end

    test "get_language/1 tenant is spanish", ~M[tenant, account] do
      Accounts.update_account(
        %{account_id: account.id, id: tenant.id},
        %{preferred_language: "spanish"}
      )

      tenant = TenantRepo.get_aggregate(tenant.id)

      res = TextMessageReplies.get_language(tenant)

      assert res == {:ok, "spanish"}
    end
  end

  describe "helpers / tenant related " do
    test "get_tenant/1 by number", ~M[tenant] do
      {:ok, list} = TextMessageReplies.get_tenant(tenant.phone)

      fetched = List.first(list)

      assert length(list) == 1
      assert fetched.id == tenant.id
    end

    test "get_tenant_balance", ~M[tenant] do
      res = TextMessageReplies.get_tenant_balance(tenant.id)

      assert Decimal.cmp(res, 950) == :eq
    end

    test "get_tenant_from_list/1 when list ", ~M[tenant] do
      {:ok, ten} =
        tenant.phone
        |> TextMessageReplies.get_tenant()
        |> TextMessageReplies.get_tenant_from_list()

      assert ten.id == tenant.id
    end

    test "get_tenant_from_list/1 when multiple ", ~M[tenant, prop_builder] do
      add_tenant(prop_builder)

      res =
        tenant.phone
        |> TextMessageReplies.get_tenant()
        |> TextMessageReplies.get_tenant_from_list()

      assert res == {:error, :multiple_tenants}
    end

    test "get_payment_source/1 correct payment source", ~M[tenant, account_builder] do
      num2 = "5432187"

      inserted_at =
        AppCount.Core.Clock.now()
        |> Timex.shift(hours: -1)
        |> Timex.to_naive_datetime()

      account_builder
      |> AccountBuilder.add_payment_source(num2: num2, inserted_at: inserted_at)

      {:ok, tenant} =
        tenant.phone
        |> TextMessageReplies.get_tenant()
        |> TextMessageReplies.get_tenant_from_list()

      payment_source = TextMessageReplies.get_payment_source(tenant.account.payment_sources)

      assert payment_source.num2 != num2
      assert payment_source.inserted_at != inserted_at
    end
  end

  describe "Replies " do
    setup do
      params = %{
        from_number: @phone,
        body: ""
      }

      ~M[params]
    end

    test "unrecognized_reply/1 english", ~M[params] do
      SmsTopic.subscribe()

      %{params | body: "some random gibberish"}
      |> TextMessageReplies.handle_message()

      expected_reply = TextMessageTemplates.unrecognized_reply("english")

      assert_receive %DomainEvent{
        topic: "sms",
        name: "sms_requested",
        content: %{phone_to: @phone, message: ^expected_reply}
      }
    end

    test "unrecognized_reply/1 spanish", ~M[params, tenant, account] do
      SmsTopic.subscribe()

      Accounts.update_account(
        %{account_id: account.id, id: tenant.id},
        %{preferred_language: "spanish"}
      )

      %{params | body: "some random gibberish"}
      |> TextMessageReplies.handle_message()

      expected_reply = TextMessageTemplates.unrecognized_reply("spanish")

      assert_receive %DomainEvent{
        topic: "sms",
        name: "sms_requested",
        content: %{phone_to: @phone, message: ^expected_reply}
      }
    end
  end
end
