defmodule AppCount.Maintenance.OrderObserver do
  use GenServer
  alias AppCount.Core.OrderTopic
  alias AppCount.Core.DomainEvent
  alias AppCount.Core.OrderTopic.Info
  require Logger

  @supported_events ["order_created", "order_assigned", "tech_dispatched", "order_completed"]

  defmodule State do
    defstruct sms_topic: AppCount.Core.SmsTopic, send_count: 0
  end

  # --- CLIENT INTERFACE --------------------------------------
  def start_link([]) do
    state = %State{}
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def start_link(name: name) do
    state = %State{}
    GenServer.start_link(__MODULE__, state, name: name)
  end

  #  --- SERVER INTERFACE -------------------------------------
  def init(%State{} = state) do
    OrderTopic.subscribe()
    {:ok, state}
  end

  # handle_info ---
  def handle_info(%DomainEvent{name: name, content: %Info{} = info}, %State{} = state)
      when name in @supported_events do
    mod_state = send_sms(state, name, info)
    {:noreply, mod_state}
  end

  def handle_info(unexpected, %State{} = state) do
    Logger.error(
      " #{List.last(String.split(__ENV__.file, "/"))}:#{__ENV__.line} handle_info UNEXPECTED: #{
        inspect(unexpected)
      }"
    )

    {:noreply, state}
  end

  # --- IMPLEMENTATION -------------------------------------------

  def send_sms(
        %State{sms_topic: sms_topic, send_count: send_count} = state,
        name,
        %Info{
          phone_to: phone_to,
          account_allow_sms: true,
          order_allow_sms: true
        } = info
      )
      when phone_to != :not_available do
    message =
      name
      |> template_for()
      |> Info.eval_string(info)

    sms_topic.sms_requested(phone_to, message, __MODULE__)

    %{state | send_count: send_count + 1}
  end

  def send_sms(state, name, %Info{} = info) do
    message = "SMS #{name} skipped because #{inspect(Map.from_struct(info))}"

    Logger.info(message)

    state
  end

  def template_for(name) do
    # TODO: add when feature is available
    # "To unsubscribe from AppRent messages reply stop."

    _order_completed_with_link =
      ~s[Hi <%= first_name %>, we are happy to inform you that your maintenance request for <%= work_order_category_name %> has been completed by  <%= tech_name %>. If it was not completed to your satisfaction, you can reopen the request by logging into your AppRent account, from there, you can rate the work order & earn 200 Reward Points! <%= order_url %>]

    order_completed_without_link =
      ~s[Hi <%= first_name %>, we are happy to inform you that your maintenance request for <%= work_order_category_name %> has been completed by  <%= tech_name %>. If it was not completed to your satisfaction, you can reopen the request by logging into your AppRent account, from there, you can rate the work order & earn 200 Reward Points!]

    %{
      "order_created" =>
        ~s[Hi <%= first_name %>, this is an automated message from <%= property_name %> to confirm that we received your work order for <%= work_order_category_name %>. We will keep you informed with updates on this request until it's closed out. You can view or edit your request from the AppRent portal.],
      "order_assigned" =>
        ~s[Hi <%= first_name %>, Great news! Your work order for <%= work_order_category_name %> has been assigned to <%= tech_name %> from <%= property_name %>. You will receive another notification in 24-48 hours when  <%= tech_name %> is on the way.],
      "tech_dispatched" =>
        ~s[Hi <%= first_name %>, <%= tech_name %> from <%=property_name %> is on the way to address your maintenance request for <%= work_order_category_name %>. You will receive another notification when the job is done.],
      "order_completed" => order_completed_without_link
    }
    |> Map.get(name, "Something Changed about your WorkOrder")
  end
end
