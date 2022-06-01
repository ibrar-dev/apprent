defmodule AppCount.Maintenance.OrderObserverTest do
  @moduledoc false
  use AppCount.Case, async: true
  alias AppCount.Maintenance.OrderObserver
  alias AppCount.Maintenance.OrderObserver.State
  alias AppCount.Core.OrderTopic
  alias AppCount.Core.OrderTopic.Info
  import ExUnit.CaptureLog
  import ShorterMaps

  defmodule SmsTopicParrot do
    use TestParrot
    @behaviour AppCount.Core.SmsTopicBehaviour
    #       scope     funtion   default-returns-value
    parrot(:sms_topic, :sms_requested, {:ok, %{}})
    parrot(:sms_topic, :message_received, {:ok, %{}})
    parrot(:sms_topic, :message_sent, {:ok, %{}})
    parrot(:sms_topic, :invalid_phone_number, {:ok, %{}})
  end

  def info() do
    %Info{
      phone_to: "+15135551234",
      account_allow_sms: true,
      order_allow_sms: true,
      order_id: 5,
      first_name: "Mickey",
      work_order_category_name: "cname",
      tech_name: "David Bowman",
      property_name: "Green Acres"
    }
  end

  def event_and_state_allows_sms(event_name) do
    state = %State{sms_topic: SmsTopicParrot}
    content = info()
    event = %{OrderTopic.event(event_name) | content: content, source: __MODULE__}
    {event, state}
  end

  def event_and_state_prohibits_sms(event_name) do
    state = %State{sms_topic: SmsTopicParrot}
    content = %{info() | account_allow_sms: false}
    event = %{OrderTopic.event(event_name) | content: content, source: __MODULE__}
    {event, state}
  end

  describe "template_for sms message" do
    test "order_created" do
      expected_template =
        ~s[Hi <%= first_name %>, this is an automated message from <%= property_name %> to confirm that we received your work order for <%= work_order_category_name %>. We will keep you informed with updates on this request until it's closed out. You can view or edit your request from the AppRent portal.]

      assert OrderObserver.template_for("order_created") == expected_template
    end

    test "invalid event name" do
      assert OrderObserver.template_for("invalid event name") ==
               "Something Changed about your WorkOrder"
    end
  end

  describe "start_link " do
    test ":ok pid", ~M[test] do
      # When
      assert {:ok, pid} = OrderObserver.start_link(name: test)
      assert Process.alive?(pid)
      Process.exit(pid, :kill)
    end
  end

  describe "order_created handle_info() " do
    test "with allow_sms" do
      {event, state} = event_and_state_allows_sms(:order_created)
      # When
      {:noreply, state} = OrderObserver.handle_info(event, state)
      # Then
      expected_message =
        ~s[Hi Mickey, this is an automated message from Green Acres to confirm that we received your work order for cname. We will keep you informed with updates on this request until it's closed out. You can view or edit your request from the AppRent portal.]

      assert_receive {:sms_requested, "+15135551234", ^expected_message,
                      AppCount.Maintenance.OrderObserver}

      assert state.send_count == 1
    end

    test "when account_allow_sms is false" do
      {event, state} = event_and_state_prohibits_sms(:order_created)
      # When
      {:noreply, state} = OrderObserver.handle_info(event, state)
      # Then
      refute_receive {:sms_requested, _, _}
      assert state.send_count == 0
    end
  end

  describe "order_assigned" do
    test "with allow_sms" do
      {event, state} = event_and_state_allows_sms(:order_assigned)
      # When
      {:noreply, state} = OrderObserver.handle_info(event, state)
      # Then
      assert state.send_count == 1

      expected_message =
        ~s[Hi Mickey, Great news! Your work order for cname has been assigned to David Bowman from Green Acres. You will receive another notification in 24-48 hours when  David Bowman is on the way.]

      assert_receive {:sms_requested, "+15135551234", ^expected_message,
                      AppCount.Maintenance.OrderObserver}
    end

    test "when account_allow_sms is false" do
      {event, state} = event_and_state_prohibits_sms(:order_assigned)
      # When
      {:noreply, state} = OrderObserver.handle_info(event, state)
      # Then
      refute_receive {:sms_requested, _, _}
      assert state.send_count == 0
    end
  end

  describe "tech_dispatched" do
    test "with allow_sms" do
      {event, state} = event_and_state_allows_sms(:tech_dispatched)
      # When
      {:noreply, state} = OrderObserver.handle_info(event, state)
      # Then
      assert_receive {:sms_requested, "+15135551234",
                      "Hi Mickey, David Bowman from Green Acres is on the way to address your maintenance request for cname. You will receive another notification when the job is done.",
                      AppCount.Maintenance.OrderObserver}

      assert state.send_count == 1
    end

    test "when account_allow_sms is false" do
      {event, state} = event_and_state_prohibits_sms(:tech_dispatched)
      # When
      {:noreply, state} = OrderObserver.handle_info(event, state)
      # Then
      refute_receive {:sms_requested, _, _}
      assert state.send_count == 0
    end
  end

  describe "order_completed" do
    test "with allow_sms" do
      {event, state} = event_and_state_allows_sms(:order_completed)
      order_id = event.content.order_id
      # When
      {:noreply, state} = OrderObserver.handle_info(event, state)
      # Then
      assert state.send_count == 1

      domain = AppCount.namespaced_url("residents")

      order_url = "#{domain}/order/#{order_id}"

      _expected_message_with_link =
        "Hi Mickey, we are happy to inform you that your maintenance request for cname has been completed by  David Bowman. If it was not completed to your satisfaction, you can reopen the request by logging into your AppRent account, from there, you can rate the work order & earn 200 Reward Points! #{
          order_url
        }"

      expected_message_without_link =
        "Hi Mickey, we are happy to inform you that your maintenance request for cname has been completed by  David Bowman. If it was not completed to your satisfaction, you can reopen the request by logging into your AppRent account, from there, you can rate the work order & earn 200 Reward Points!"

      assert_receive {:sms_requested, "+15135551234", ^expected_message_without_link,
                      AppCount.Maintenance.OrderObserver}
    end

    test "when account_allow_sms is false" do
      {event, state} = event_and_state_prohibits_sms(:order_completed)
      # When
      {:noreply, state} = OrderObserver.handle_info(event, state)
      # Then
      refute_receive {:sms_requested, _, _}
      assert state.send_count == 0
    end
  end

  describe "send_sms with various errors" do
    def event_and_state_content(content) do
      state = %State{sms_topic: SmsTopicParrot}
      event = %{OrderTopic.event(:order_created) | content: content, source: __MODULE__}
      {event, state}
    end

    test "when account_allow_sms is false" do
      state = %State{sms_topic: SmsTopicParrot}
      info = %{info() | account_allow_sms: false}

      # When
      log_messages =
        capture_log(fn ->
          OrderObserver.send_sms(state, "order_created", info)
        end)

      assert log_messages =~
               ~s<[info]  SMS order_created skipped because %{account_allow_sms: false, first_name: "Mickey", order_allow_sms: true, order_id: 5, phone_to: "+15135551234", property_name: "Green Acres", tech_name: "David Bowman", work_order_category_name: "cname"}>
    end

    test "when phone_to :not_available" do
      state = %State{sms_topic: SmsTopicParrot}
      info = %{info() | phone_to: :not_available}

      # When
      log_messages =
        capture_log(fn ->
          OrderObserver.send_sms(state, "order_created", info)
        end)

      assert log_messages =~
               ~s<[info]  SMS order_created skipped because %{account_allow_sms: true, first_name: \"Mickey\", order_allow_sms: true, order_id: 5, phone_to: :not_available, property_name: "Green Acres", tech_name: "David Bowman", work_order_category_name: "cname"}>
    end
  end
end
