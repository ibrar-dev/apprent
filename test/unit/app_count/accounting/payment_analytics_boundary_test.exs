defmodule AppCount.Accounting.PaymentAnalyticsBoundaryTest do
  use AppCount.DataCase
  alias AppCount.Accounting
  alias AppCount.Accounting.PaymentAnalyticsBoundary

  setup do
    [builder, property] =
      PropBuilder.new(:create)
      |> PropBuilder.add_property()
      |> PropBuilder.add_unit()
      |> PropBuilder.get([:property])

    ~M[builder, property]
  end

  def add_tenant(builder) do
    builder
    |> PropBuilder.add_tenant()
    |> PropBuilder.add_customer_ledger()
    |> PropBuilder.add_tenancy()
  end

  def tenant_with_login(builder) do
    add_tenant(builder)
    |> PropBuilder.add_tenant_account()
    |> PropBuilder.add_account_login()
  end

  describe "payment analytics" do
    setup(~M[builder]) do
      naive_times =
        AppTime.new()
        |> AppTime.start_of_month()
        |> AppTime.to_naive(:start_of_month)
        |> AppTime.plus_to_naive(:now, minutes: 0)
        |> AppTime.times()

      builder =
        add_tenant(builder)
        |> PropBuilder.add_payment()
        |> PropBuilder.add_payment(inserted_at: naive_times.start_of_month)

      ~M[builder]
    end

    def add_payments(builder, num) do
      1..num
      |> Enum.each(fn _ -> PropBuilder.add_payment(builder) end)
    end

    def dates() do
      times =
        AppTime.new()
        |> AppTime.start_of_month()
        |> AppTime.plus(:now, minutes: 0)
        |> AppTime.times()

      "#{Timex.format!(times.start_of_month, "{YYYY}-{0M}-{0D}")},#{
        Timex.format!(times.now, "{YYYY}-{0M}-{0D}")
      }"
    end

    # This test should no longer fail on the first of the month.
    test "info_boxes_payment_analytics/1", ~M[property] do
      client = AppCount.Public.get_client_by_schema("dasmen")

      %{
        number_of_payments: payments,
        payments_amount: payments_sums,
        tenants_with_autopay: tenants_autopay,
        tenants_with_no_login: tenants_login
      } = Accounting.info_boxes_payment_analytics([property.id], client.client_schema)

      payments_right =
        if Timex.today().day == 1 do
          %{day_of: 2, mtd: 2}
        else
          %{day_of: 1, mtd: 2}
        end

      payments_sums_right =
        if Timex.today().day == 1 do
          %{day_of: Decimal.new(2000), mtd: Decimal.new(2000)}
        else
          %{day_of: Decimal.new(1000), mtd: Decimal.new(2000)}
        end

      assert payments == payments_right
      assert payments_sums == payments_sums_right
      assert tenants_autopay == 0
      assert tenants_login == 1
    end

    test "charts_payment_analytics/2", ~M[builder, property] do
      client = AppCount.Public.get_client_by_schema("dasmen")

      # Two payments get added in setup, so assert that 2 plus whatever number you enter below
      # TODO expand on this test so it tests more than just the length
      add_payments(builder, 8)

      res = Accounting.charts_payment_analytics([property.id], dates(), client.client_schema)

      assert length(res) == 10
    end
  end

  describe "non main functions" do
    test "reduce_for_amount/1 returns 0" do
      res = PaymentAnalyticsBoundary.reduce_for_amount([])
      assert res == 0
    end
  end
end
