defmodule AppCount.Admins.EmailSubscriptionsRepoTest do
  use AppCount.DataCase
  alias AppCount.Admins.EmailSubscriptionsRepo, as: EmailsRepo
  alias AppCount.Core.ClientSchema

  setup do
    [_builder, admin] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_admin_with_access()
      |> PropBuilder.get([:admin])

    ~M[admin]
  end

  describe "create functions" do
    test "works", ~M[admin] do
      client = AppCount.Public.get_client_by_schema("dasmen")

      %{
        admin_id: admin.id,
        trigger: "triggered",
        active: true
      }
      |> EmailsRepo.insert(prefix: client.client_schema)

      res = EmailsRepo.subscribed?(ClientSchema.new(client.client_schema, admin.id), "triggered")

      assert res
    end

    test "does not create if already subscribed", ~M[admin] do
      params = %{
        admin_id: admin.id,
        trigger: "triggered",
        active: true
      }

      EmailsRepo.insert(params)

      {:error, changeset} = EmailsRepo.insert(params)

      assert changeset.errors == [
               trigger:
                 {"admin already subscribed",
                  [
                    constraint: :unique,
                    constraint_name: "admins__email_subscriptions_admin_id_trigger_index"
                  ]}
             ]
    end
  end

  describe "subscribe/unsubscribe functions" do
    test "subscribe/2", ~M[admin] do
      trigger = "trigger_1"

      client = AppCount.Public.get_client_by_schema("dasmen")
      EmailsRepo.subscribe(ClientSchema.new(client.client_schema, admin.id), trigger)

      res = EmailsRepo.subscribed?(ClientSchema.new(client.client_schema, admin.id), trigger)

      assert res
    end

    test "subscribe/2 updates when previosly subscribed", ~M[admin] do
      trigger = "trigger_3"

      client = AppCount.Public.get_client_by_schema("dasmen")

      {:ok, first} =
        EmailsRepo.subscribe(ClientSchema.new(client.client_schema, admin.id), trigger)

      EmailsRepo.unsubscribe(ClientSchema.new(client.client_schema, admin.id), trigger)

      {:ok, second} =
        EmailsRepo.subscribe(ClientSchema.new(client.client_schema, admin.id), trigger)

      assert first.id == second.id
      assert EmailsRepo.subscribed?(ClientSchema.new(client.client_schema, admin.id), trigger)
    end

    test "unsubscribe/2", ~M[admin] do
      trigger = "trigger_2"
      client = AppCount.Public.get_client_by_schema("dasmen")
      EmailsRepo.subscribe(ClientSchema.new(client.client_schema, admin.id), trigger)

      EmailsRepo.unsubscribe(ClientSchema.new(client.client_schema, admin.id), trigger)

      res = EmailsRepo.subscribed?(ClientSchema.new(client.client_schema, admin.id), trigger)

      refute res
    end
  end

  test "get_admins/1", ~M[admin] do
    trigger = "get_trigger"
    client = AppCount.Public.get_client_by_schema("dasmen")

    EmailsRepo.subscribe(ClientSchema.new(client.client_schema, admin.id), trigger)

    [subscription] = res = EmailsRepo.get_admins(ClientSchema.new(client.client_schema, trigger))

    assert length(res) == 1
    assert not is_nil(subscription.admin)
  end
end
