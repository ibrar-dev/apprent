defmodule AppCount.Tasks.Workers.DailyPaymentsEmail do
  use AppCount.Tasks.Worker, "Send Daily Payments Email"
  alias AppCount.Core.DateTimeRange
  alias AppCount.Ledgers.PaymentRepo
  alias AppCount.Properties.PropertyRepo
  alias AppCount.Admins.EmailSubscriptionsRepo
  alias AppCount.Admins.EmailSubscription
  alias AppCount.Admins
  alias AppCount.Core.ClientSchema

  @impl AppCount.Tasks.Worker
  def perform(client_schema \\ "dasmen") do
    payments = get_payments(%AppCount.Core.ClientSchema{name: client_schema})

    properties =
      all_properties(%AppCount.Core.ClientSchema{name: client_schema})
      |> merge_and_flatten(payments)

    EmailSubscriptionsRepo.get_admins(ClientSchema.new(client_schema, "daily_payments"))
    |> Enum.each(&filter_and_send(&1, properties))
  end

  # Filter out the payments that belong to the admins property
  def filter_and_send(%EmailSubscription{admin: admin}, properties) do
    filtered = filtered_payments(admin, properties)

    case length(filtered) do
      0 -> nil
      _ -> AppCountCom.Admins.send_daily_payments(admin, filtered)
    end
  end

  def filtered_payments(admin, properties) do
    property_ids = Admins.property_ids_for(ClientSchema.new(admin.__meta__.prefix, admin))

    properties
    |> Enum.filter(&(&1.id in property_ids))
  end

  # Get all payments within the last 24 hours, so DB only gets called once.
  def get_payments(%AppCount.Core.ClientSchema{name: client_schema}) do
    date_range = DateTimeRange.last24hours()

    property_ids =
      all_properties(%AppCount.Core.ClientSchema{name: client_schema})
      |> Enum.map(& &1.id)

    PaymentRepo.payments_in(date_range, ClientSchema.new(client_schema, property_ids))
  end

  def all_properties(%AppCount.Core.ClientSchema{name: client_schema}) do
    ClientSchema.new(client_schema, fake_admin())
    |> Admins.property_ids_for()
    |> Enum.map(&PropertyRepo.info_for_email(&1))
  end

  defp merge_and_flatten(properties, payments) do
    properties
    |> Enum.map(fn p ->
      filtered = Enum.filter(payments, &(&1.property_id == p.id))

      total_paid =
        Enum.reduce(filtered, Decimal.new(0), fn p, acc ->
          Decimal.add(acc, p.amount)
        end)

      Map.merge(p, %{payments: filtered, total_paid: total_paid})
    end)
    |> Enum.filter(&(length(&1.payments) > 0))
  end

  # To get all the property_ids
  defp fake_admin() do
    %{
      id: "",
      roles: %MapSet{
        map: %{
          "Super Admin" => ""
        }
      }
    }
  end
end
