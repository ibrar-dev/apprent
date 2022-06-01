defmodule AppCount.Messaging.TextMessageRepo do
  use AppCount.Core.GenericRepo,
    schema: AppCount.Messaging.TextMessage

  alias AppCount.Core.SmsTopic

  def create(params) do
    params
    |> insert()
    |> publish_creation()
  end

  def messages_by_num(num) do
    from(
      m in @schema,
      where: m.from_number == ^num or m.to_number == ^num,
      order_by: [asc: :inserted_at]
    )
    |> Repo.all()
  end

  def publish_creation(
        {:ok, %{direction: "incoming", from_number: from, to_number: to} = params} = text
      ) do
    SmsTopic.message_received({from, to, params}, __MODULE__)
    text
  end

  # Loopty Loop.
  # Order Completed -> SMS Sent to resident -> SMS Saved -> publish_creation below hit. -> SmsTopic.message_sent/2 triggers a new attempt to send SMS.
  # The last part of the above loop fails, causing the TwilioPort to eventually crash.
  # Short term fix: no need to broadcast in below function.
  # Big Question: This has been happening for about a month, why are things crashing now?
  def publish_creation({:ok, _} = text) do
    #   {:ok, %{direction: "outgoing", from_number: from, to_number: to} = params} = text
    # ) do
    # SmsTopic.message_sent({from, to, params}, __MODULE__)
    text
  end

  def publish_creation(err), do: err

  # TODO: Move these.
  def format_number(nil, _), do: ""

  def format_number("+1" <> _rest = num, type),
    do: format_number(String.slice(num, 2, 999), type)

  def format_number(number, :no_country_code) do
    Regex.replace(~r/\D+/, number, "")
  end

  def format_number(number, :country_code) do
    "+1" <> format_number(number, :no_country_code)
  end
end
