defmodule AppCount.Ledgers.PaymentRepoTest do
  use AppCount.DataCase
  alias AppCount.Ledgers.PaymentRepo
  alias AppCount.Core.DateTimeRange
  alias AppCount.Core.ClientSchema

  setup do
    times =
      AppTime.new()
      |> AppTime.plus(:minus_ten, minutes: -10)
      |> AppTime.plus(:minus_five, minutes: -5)
      |> AppTime.plus(:now, minutes: 0)
      |> AppTime.plus(:plus_five, minutes: 5)
      |> AppTime.plus(:plus_ten, minutes: 10)
      |> AppTime.times()

    naive_times = AppTime.to_naive(times)

    [builder, property] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_payment(inserted_at: naive_times.minus_ten)
      |> PropBuilder.add_payment(inserted_at: naive_times.minus_five)
      |> PropBuilder.add_payment(inserted_at: naive_times.now)
      |> PropBuilder.add_payment(inserted_at: naive_times.plus_five)
      |> PropBuilder.add_payment(inserted_at: naive_times.plus_ten)
      |> PropBuilder.get([:property])

    ~M[times, property, builder]
  end

  describe "payments_in" do
    test "in range past [minus_ten, minus_five, now]", ~M[times, property] do
      range = DateTimeRange.new(times.minus_ten, times.now)
      payments = PaymentRepo.payments_in(range, ClientSchema.new("dasmen", [property.id]))

      assert length(payments) == 3
    end

    test "in range future [ plus_five, plus_ten]", ~M[times, property] do
      range = DateTimeRange.new(times.plus_five, times.plus_ten)
      payments = PaymentRepo.payments_in(range, ClientSchema.new("dasmen", [property.id]))

      assert length(payments) == 2
    end
  end

  describe "show_payment/1" do
    setup(~M[builder]) do
      [_, payment] =
        builder
        |> PropBuilder.add_unit()
        |> PropBuilder.add_tenant()
        |> PropBuilder.add_customer_ledger()
        |> PropBuilder.add_ledger_charge()
        |> PropBuilder.add_tenancy()
        |> PropBuilder.add_payment()
        |> PropBuilder.get([:payment])

      ~M[payment]
    end

    # If this ever fails theres an issue with linking the tenancy to the payment/tenant
    test "working with tenancy", ~M[payment] do
      res = PaymentRepo.show_payment(payment.id)

      refute is_nil(res.unit)
      refute is_nil(res.tenant_name)
      assert res.id == payment.id
      assert res.amount == payment.amount
    end
  end
end
