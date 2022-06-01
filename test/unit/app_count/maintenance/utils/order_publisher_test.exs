defmodule AppCount.Maintenance.Utils.OrderPublisherTest do
  use AppCount.DataCase
  alias AppCount.Accounts.Account
  alias AppCount.Maintenance.OrderRepo
  alias AppCount.Maintenance.Utils.OrderPublisher
  alias AppCount.Core.OrderTopic

  setup do
    order = Factory.insert(:order)
    order = OrderRepo.get_aggregate(order.id)
    assignment = Factory.insert(:assignment, order: order)
    order = assignment.order
    _account = create_an_account(order.tenant)
    OrderTopic.subscribe()

    ~M[assignment, order]
  end

  def create_an_account(tenant) do
    attrs = %{
      password: "secret agent man",
      tenant_id: tenant.id,
      username: "AccountHolder-#{Enum.random(1..100_000)}",
      property_id: Factory.insert(:property).id
    }

    account =
      Account.new(attrs)
      |> Account.changeset(%{allow_sms: true})
      |> AppCount.Repo.insert!()

    account
  end

  describe "publish_order_created_event" do
    test "order_created", ~M[order] do
      order
      |> OrderPublisher.publish_order_created_event()

      assert_receive %{topic: "order", name: "order_created"}
    end

    test "tech_dispatched", ~M[assignment] do
      assignment
      |> OrderPublisher.publish_tech_dispatched_event()

      assert_receive %{topic: "order", name: "tech_dispatched"}
    end

    test "order_assigned", ~M[assignment] do
      assignment
      |> OrderPublisher.publish_order_assigned_event()

      assert_receive %{topic: "order", name: "order_assigned"}
    end

    test "order_completed", ~M[assignment] do
      assignment
      |> OrderPublisher.publish_order_completed_event()

      assert_receive %{topic: "order", name: "order_completed"}
    end
  end

  describe "load_info/1" do
    test "assignment", ~M[assignment, order] do
      # When
      info = OrderPublisher.load_info(assignment)

      expected_first_name = order.tenant.first_name
      expected_order_id = order.id
      expected_order_category = order.category.name

      assert %AppCount.Core.OrderTopic.Info{
               account_allow_sms: true,
               first_name: ^expected_first_name,
               order_allow_sms: true,
               order_id: ^expected_order_id,
               phone_to: :not_available,
               work_order_category_name: ^expected_order_category,
               property_name: "Test Property"
             } = info
    end

    test "includes tech_name", ~M[assignment] do
      info = OrderPublisher.load_info(assignment)
      expected_tech_name = assignment.tech.name
      assert info.tech_name == expected_tech_name
    end
  end
end
