defmodule AppCountWeb.Users.DashboardView do
  use AppCountWeb.Users, :view

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

  #  def due_date_short(_billing_info), do: Timex.format!(AppCount.current_time(), "{D}/{M}/{YYYY}")

  def total_due(billing_info) when is_list(billing_info) do
    billing_info
    |> Enum.reduce(Decimal.new(0), &Decimal.add(&2, &1.balance))
  end

  #  def total_due(%Decimal{} = billing_info), do: billing_info

  def filter_packages(packages, filter) do
    packages
    |> Enum.filter(&(&1.status == filter))
  end

  def filtered_orders(orders, filters) when is_list(filters) do
    orders
    |> Enum.filter(&Enum.member?(filters, &1.status))
  end

  def filtered_orders(orders, filters) do
    orders
    |> Enum.filter(&(&1.status == filters))
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

  def get_class_of_button(nil, :inverse), do: "danger"

  def get_class_of_button(%{active: active}, :inverse) do
    if active do
      "primary"
    else
      "danger"
    end
  end

  def active_autopay?(nil), do: "checked"

  def active_autopay?(%{active: active, id: id}) when not is_nil(id) do
    if active and id do
      true
    else
      false
    end
  end

  def active_autopay?(%{active: active}) do
    if active do
      true
    else
      false
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

  def disabled_enabled(nil), do: "disabled"

  def disabled_enabled(%{active: active}) do
    if active do
      "enabled"
    else
      "disabled"
    end
  end

  def image_url(nil), do: ""
  def image_url(url), do: URI.encode(url)
end
