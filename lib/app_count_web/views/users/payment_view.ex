defmodule AppCountWeb.Users.PaymentView do
  use AppCountWeb.Users, :view

  def account_num(property_id \\ "") do
    ("0000" <> "#{property_id}")
    |> String.slice(-4, 4)
  end

  # Format a Credit Card as "Visa: XXXX 1234"
  def payment_source_display_name(%{type: "cc"} = source) do
    "#{String.capitalize(source.brand)}: XXXX #{source.last_4}"
  end

  # Format a bank account as "Checking: XXXX 1234" or "Savings: XXXX 1234"
  def payment_source_display_name(%{type: "ba"} = source) do
    "#{String.capitalize(source.subtype)}: XXXX #{source.last_4}"
  end

  def due_date([]) do
    nil
  end

  def due_date(billing_info) when is_list(billing_info) do
    billing_info
    |> hd()
    |> Map.get(:date)
    |> Timex.parse!("{M}/{YYYY}")
    |> Timex.format!("{Mfull} 01, {YYYY}")
  end

  #  def due_date(_billing_info) do
  #    Timex.format!(AppCount.current_time(), "{D}/{M}/{YYYY}")
  #  end

  def due_date_short(billing_info) when is_list(billing_info) do
    case length(billing_info) do
      0 ->
        Timex.format!(AppCount.current_time(), "{D}/{M}/{YYYY}")

      _ ->
        billing_info
        |> hd()
        |> Map.get(:date)
        |> Timex.parse!("{M}/{YYYY}")
        |> Timex.format!("{D}/{M}/{YYYY}")
    end
  end

  def due_date_short(_billing_info), do: Timex.format!(AppCount.current_time(), "{D}/{M}/{YYYY}")

  def total_due(billing_info) when is_list(billing_info) do
    billing_info
    |> Enum.reduce(Decimal.new(0), &Decimal.add(&2, &1.balance))
  end

  def next_autopay_date() do
    Timex.today()
    |> Timex.shift(months: 1)
    |> Timex.format!("{WDfull}, {Mfull} 01, {YYYY}")
  end

  def get_class_of_button(nil), do: "primary"

  def get_class_of_button(%{active: active}) do
    if active do
      "danger"
    else
      "primary"
    end
  end

  def active_autopay?(nil), do: "checked"

  def active_autopay?(%{active: active}) do
    if active do
      "checked"
    else
      ""
    end
  end

  def enable_disable(nil), do: "Enable"

  def enable_disable(%{active: active}) do
    if active do
      "Disable"
    else
      "Enable"
    end
  end

  def enable_disable(nil, :inverse), do: "Disable"

  def enable_disable(%{active: active}, :inverse) do
    if active do
      "Enable"
    else
      "Disable"
    end
  end

  #  def total_due(%Decimal{} = billing_info), do: billing_info
end
