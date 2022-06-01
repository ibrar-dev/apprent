defmodule AppCount.Core.Ports.PaymentPortTest do
  use AppCount.Case
  alias AppCount.Core.Ports.PaymentPort

  defmodule AuthorizePaymentParrot do
    use TestParrot
    parrot(:payment, :process_payment, {:ok, %{transaction_id: "Authorize-transaction_id"}})
  end

  alias AppCount.Core.Ports.PaymentPortTest.AuthorizePaymentParrot

  defmodule PayscapePaymentParrot do
    use TestParrot
    parrot(:payment, :process_payment, {:ok, %{transaction_id: "Payscape-transaction_id"}})
  end

  alias AppCount.Core.Ports.PaymentPortTest.PayscapePaymentParrot

  test "process payment for Authorize" do
    processor = %{name: "Authorize"}
    source = %{}
    amount_in_cents = 100_000

    adapters = %{cc: AuthorizePaymentParrot, ba: PayscapePaymentParrot}

    # When
    result = PaymentPort.process_payment(amount_in_cents, source, processor, adapters)

    # Then
    assert result == {:ok, %{transaction_id: "Authorize-transaction_id"}}
  end

  test "process payment for Payscape" do
    processor = %{name: "Payscape"}
    source = %{}
    amount_in_cents = 100_000

    adapters = %{cc: AuthorizePaymentParrot, ba: PayscapePaymentParrot}

    # When
    result = PaymentPort.process_payment(amount_in_cents, source, processor, adapters)

    # Then
    assert result == {:ok, %{transaction_id: "Payscape-transaction_id"}}
  end
end
