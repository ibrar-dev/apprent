defmodule AppCount.Core.Ports.PaymentPort do
  alias AppCount.Adapters.AuthorizeAdapter
  alias AppCount.Adapters.PayscapeAdapter

  @authorize_adapter AppCount.adapters(:credit_card, AuthorizeAdapter)
  @payscape_adapter AppCount.adapters(:bank_account, PayscapeAdapter)

  @defaults %{cc: @authorize_adapter, ba: @payscape_adapter}

  def process_payment(amount_in_dollars, payment_source, processor, adapters \\ @defaults)

  def process_payment(
        amount_in_dollars,
        payment_source,
        %{name: "Authorize"} = processor,
        adapters
      ) do
    adapters.cc.process_payment(amount_in_dollars, payment_source, processor)
  end

  def process_payment(
        amount_in_dollars,
        payment_source,
        %{name: "Payscape"} = processor,
        adapters
      ) do
    adapters.ba.process_payment(amount_in_dollars, payment_source, processor)
  end
end
